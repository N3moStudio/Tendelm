import SwiftUI
import SwiftData
import TendelmCore

struct TimeSinceView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.habitTheme) private var theme
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled
    @Query(sort: \TimeSinceRecord.startedAt) private var records: [TimeSinceRecord]
    @State private var showsNew = false
    @State private var undoAction: TimeSinceUndoAction?
    @State private var error: String?
    @State private var feedback = 0

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
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 14) {
                            Text("One moment at a time.")
                                .font(.subheadline).foregroundStyle(Color.kadoForegroundSecondary)
                            ForEach(records.map { $0.snapshot }) { tracker in
                                card(tracker)
                            }
                        }
                        .padding().frame(maxWidth: 620)
                        .frame(maxWidth: .infinity)
                    }
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
        }
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
