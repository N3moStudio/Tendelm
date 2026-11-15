import SwiftUI
import SwiftData
import TendelmCore

struct TimeSinceView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.habitTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled
    @Query(sort: \TimeSinceRecord.startedAt) private var records: [TimeSinceRecord]
    @State private var showsNew = false
    @State private var undoAction: TimeSinceUndoAction?
    @State private var error: String?
    @State private var feedback = 0
    @State private var reorder = ReorderSession()
    @Environment(\.scenePhase) private var scenePhase

    private var trackers: [TimeSinceTracker] { reorder.ordered(ItemOrdering.trackers(records.map { $0.snapshot })) }

    var body: some View {
        NavigationStack {
            Group {
                if records.isEmpty {
                    ContentUnavailableView {
                        Label("A little more space", systemImage: "leaf")
                    } description: {
                        Text("Name something you want to step away from. We'll keep track of the time.")
                    } actions: {
                        Button("Start a tracker") { showsNew = true }
                            .buttonStyle(.borderedProminent)
                    }
                } else {
                    List {
                        Text("One moment at a time.")
                            .font(.subheadline).foregroundStyle(Color.kadoForegroundSecondary)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .moveDisabled(true)
                        ForEach(trackers) { tracker in
                            card(tracker)
                                .frame(maxWidth: 620)
                                .frame(maxWidth: .infinity)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 7, leading: 16, bottom: 7, trailing: 16))
                        }

                        Text("Hold and drag the handle to reorder. Hold the tracker for Delete.")
                            .font(.footnote).foregroundStyle(Color.kadoForegroundSecondary)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .moveDisabled(true)
                    }
                    .listStyle(.plain)
                    .onDisappear { reorder.cancel() }
                    .onChange(of: scenePhase) { _, phase in if phase != .active { reorder.cancel() } }
                    .onChange(of: records.map(\.id)) { _, _ in reorder.cancel() }
                    .scrollContentBackground(.hidden)
                    .transaction { if reduceMotion { $0.animation = nil } }

                }
            }
            .background(Color.kadoBackground.ignoresSafeArea())
            .timeSinceUndo($undoAction, perform: undo)
            .navigationTitle("Time since")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { undoAction = nil; showsNew = true } label: { Label("New tracker", systemImage: "plus") }
                        .accessibilityIdentifier("timeSince.new")
                }
            }
            .sheet(isPresented: $showsNew) { TimeSinceEditor(tracker: nil) }
            .navigationDestination(for: UUID.self) { id in TimeSinceDetailView(trackerID: id) }
            .sensoryFeedback(.impact(weight: .light), trigger: feedback)
            .alert("Couldn't update tracker", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
                Button("Close", role: .cancel) {}
            } message: { Text(error ?? "") }
        }
    }

    private func card(_ tracker: TimeSinceTracker) -> some View {
        TimeSinceStartGate(start: tracker.currentStart) { now in
            let index = trackers.firstIndex(where: { $0.id == tracker.id }) ?? 0
            ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 16) {
                NavigationLink(value: tracker.id) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .firstTextBaseline) {
                            Image(systemName: "leaf.fill").foregroundStyle(tracker.color.color(in: theme))
                                .accessibilityHidden(true)
                            Text(tracker.name).font(.headline).foregroundStyle(Color.kadoForeground)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: 8)
                            Image(systemName: "chevron.right").font(.caption).foregroundStyle(Color.kadoForegroundSecondary)
                                .accessibilityHidden(true)
                        }
                        ElapsedTimeLabel(start: tracker.currentStart)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.trailing, 44)
                .accessibilityIdentifier("timeSince.detail.\(tracker.id)")
                HStack {
                    Button("Log a reset", systemImage: "arrow.counterclockwise") { reset(tracker.id) }
                        .buttonStyle(.bordered).tint(Color.kadoAccent)
                        .frame(minHeight: 44)
                        .accessibilityHint("Records an occurrence and starts counting again. You can undo it.")
                        .accessibilityIdentifier("timeSince.reset.\(tracker.id)")
                        .disabled(now < tracker.currentStart)
                    Spacer(minLength: 8)
                }
            }
            .padding(18)
            .background(Color.kadoBackgroundSecondary, in: RoundedRectangle(cornerRadius: 20))
            .contextMenu {
                Button("Delete", systemImage: "trash", role: .destructive) { moveToRecentlyDeleted(tracker.id) }
                    .accessibilityIdentifier("tracker.delete")
            }
            .accessibilityAction(named: "Delete") { moveToRecentlyDeleted(tracker.id) }
            ReorderGrip(name: tracker.name, identifier: "reorder.tracker.\(tracker.id)",
                id: tracker.id,
                begin: { reorder.begin(tracker.id, among: trackers.map(\.id), reduceMotion: reduceMotion) },
                end: { reorder.cancel() },
                moveUp: index > 0 ? { moveTrackers(from: IndexSet(integer: index), to: index - 1) } : nil,
                moveDown: index + 1 < trackers.count ? { moveTrackers(from: IndexSet(integer: index), to: index + 2) } : nil)
                .padding(10)
            }
            .onDrop(of: [ReorderDragSource.typeIdentifier],
                    delegate: ReorderDropDelegate(session: reorder, target: tracker.id, commit: saveTrackerOrder))
        }
    }

    private func moveTrackers(from source: IndexSet, to destination: Int) {
        var ids = trackers.map(\.id)
        ids.move(fromOffsets: source, toOffset: destination)
        _ = saveTrackerOrder(ids)
    }

    private func saveTrackerOrder(_ ids: [UUID]) -> Bool {
        do {
            try ItemOrderStore().trackers(ids, in: context)
            feedback += 1
            return true
        } catch { self.error = error.localizedDescription; return false }
    }

    private func moveToRecentlyDeleted(_ id: UUID) {
        do {
            undoAction = nil
            try RecentlyDeletedStore().moveTracker(id: id, in: context)
            WidgetReloader.reloadAll(using: context)
        } catch { self.error = error.localizedDescription }
    }

    private func reset(_ id: UUID) {
        guard var value = records.first(where: { $0.id == id })?.snapshot else { return }
        do {
            let change = try value.reset(at: .now)
            try TimeSinceStore().save(value, in: context)
            undoAction = TimeSinceUndoAction(trackerID: id, change: .added(change),
                lifetime: .seconds(voiceOverEnabled ? 20 : 6))
            feedback += 1
        } catch { self.error = String(localized: "The reset wasn't saved. Check the device time and try again.") }
    }

    private func undo() {
        guard let action = undoAction,
              var value = records.first(where: { $0.id == action.trackerID })?.snapshot else { return }
        do {
            guard try action.undo(in: &value) else { undoAction = nil; return }
            try TimeSinceStore().save(value, in: context)
            undoAction = nil
            feedback += 1
        }
        catch { self.error = error.localizedDescription }
    }
}

#Preview("Dark") {
    TimeSinceView().modelContainer(for: [TimeSinceRecord.self, TimeSinceResetRecord.self], inMemory: true)
        .kadoTheme().preferredColorScheme(.dark)
}
