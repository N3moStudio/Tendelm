import SwiftUI
import SwiftData
import TendelmCore

struct TimeSinceView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.habitTheme) private var theme
    @Query(sort: \TimeSinceRecord.startedAt) private var records: [TimeSinceRecord]
    @State private var showsNew = false
    @State private var undoIDs: [UUID: UUID] = [:]
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
            .navigationTitle("Time since")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showsNew = true } label: { Label("New tracker", systemImage: "plus") }
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
        TimeSinceClock(start: tracker.currentStart) { now in
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
                        ElapsedTimeLabel(start: tracker.currentStart, now: now)
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
                    if undoIDs[tracker.id] == tracker.orderedResets.last?.id, undoIDs[tracker.id] != nil {
                        Button("Undo") { undo(tracker.id) }.frame(minHeight: 44)
                            .accessibilityIdentifier("timeSince.undo.\(tracker.id)")
                    }
                }
            }
            .padding(18)
            .background(Color.kadoBackgroundSecondary, in: RoundedRectangle(cornerRadius: 20))
        }
    }

    private func reset(_ id: UUID) {
        guard var value = records.first(where: { $0.id == id })?.snapshot else { return }
        do {
            try value.reset(at: .now)
            try TimeSinceStore().save(value, in: context)
            undoIDs[id] = value.orderedResets.last?.id
            feedback += 1
        } catch { self.error = String(localized: "The reset wasn't saved. Check the device time and try again.") }
    }

    private func undo(_ id: UUID) {
        guard var value = records.first(where: { $0.id == id })?.snapshot,
              value.orderedResets.last?.id == undoIDs[id] else { return }
        value.undoLastReset()
        do { try TimeSinceStore().save(value, in: context); undoIDs[id] = nil; feedback += 1 }
        catch { self.error = error.localizedDescription }
    }
}

#Preview("Dark") {
    TimeSinceView().modelContainer(for: [TimeSinceRecord.self, TimeSinceResetRecord.self], inMemory: true)
        .kadoTheme().preferredColorScheme(.dark)
}
