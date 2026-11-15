import SwiftUI
import SwiftData
import TendelmCore

struct TimeSinceDetailView: View {
    let trackerID: UUID
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.calendar) private var calendar
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled
    @Query private var records: [TimeSinceRecord]
    private enum Sheet: String, Identifiable {
        case edit, previousReset
        var id: String { rawValue }
    }
    @State private var sheet: Sheet?
    @State private var showsDelete = false
    @State private var undoAction: TimeSinceUndoAction?
    @State private var error: String?
    @State private var feedback = 0

    private var tracker: TimeSinceTracker? { records.first { $0.id == trackerID }?.snapshot }

    var body: some View {
        Group {
            if let value = tracker {
                List {
                    Section {
                        TimeSinceStartGate(start: value.currentStart) { now in
                            VStack(alignment: .leading, spacing: 16) {
                                Text(value.name).font(.title2.weight(.semibold))
                                    .fixedSize(horizontal: false, vertical: true)
                                VStack(alignment: .leading, spacing: 10) {
                                    Text(now < value.currentStart ? "Scheduled start" : "Time since last reset")
                                        .font(.subheadline).foregroundStyle(Color.kadoForegroundSecondary)
                                    ElapsedTimeLabel(start: value.currentStart, showsSeconds: true)
                                }
                                Text(now < value.currentStart
                                    ? "Starts \(value.currentStart.formatted(date: .abbreviated, time: .shortened))"
                                    : "Since \(value.currentStart.formatted(date: .abbreviated, time: .shortened))")
                                    .font(.footnote).foregroundStyle(Color.kadoForegroundSecondary)
                                VStack(alignment: .leading, spacing: 8) { resetActions(value, now: now) }
                                    .font(.subheadline)
                            }.padding(.vertical, 8)
                        }
                    } footer: {
                        Text("A reset records what happened. Your earlier time still counts.")
                    }
                    .listRowBackground(Color.kadoBackgroundSecondary)
                    let groups = Dictionary(grouping: value.orderedResets) { event in
                        calendar.dateInterval(of: .month, for: event.date)?.start ?? event.date
                    }
                    ForEach(groups.keys.sorted(by: >), id: \.self) { month in
                    Section(month.formatted(.dateTime.month(.wide).year())) {
                        ForEach((groups[month] ?? []).reversed()) { event in
                            VStack(alignment: .leading, spacing: 4) {
                                ViewThatFits(in: .horizontal) {
                                    HStack {
                                        Text(event.date, format: .dateTime.month(.abbreviated).day()).fontWeight(.medium)
                                        Spacer()
                                        Text(event.date, format: .dateTime.hour().minute().second()).monospacedDigit()
                                    }
                                    Text(event.date, format: .dateTime.day().month().year().hour().minute().second())
                                }
                                Text("Reset logged")
                                    .font(.footnote).foregroundStyle(Color.kadoForegroundSecondary)
                            }
                            .accessibilityElement(children: .combine)
                            .accessibilityIdentifier("timeSince.history.\(event.id)")
                            .accessibilityAction(named: Text("Delete reset")) { deleteReset(event.id) }
                            .contextMenu {
                                Button("Delete reset", systemImage: "trash", role: .destructive) { deleteReset(event.id) }
                                    .accessibilityIdentifier("timeSince.history.menuDelete.\(event.id)")
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button("Delete", systemImage: "trash", role: .destructive) { deleteReset(event.id) }
                                    .accessibilityIdentifier("timeSince.history.delete.\(event.id)")
                            }
                        }
                    }.listRowBackground(Color.kadoBackgroundSecondary)
                    }
                    Section("Start date") {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Tracking began")
                            Text(value.startedAt, format: .dateTime.day().month().year().hour().minute())
                                .font(.footnote).foregroundStyle(Color.kadoForegroundSecondary)
                        }
                    }.listRowBackground(Color.kadoBackgroundSecondary)
                }
                .scrollContentBackground(.hidden)
            } else {
                ContentUnavailableView("Tracker unavailable", systemImage: "leaf")
            }
        }
        .background(Color.kadoBackground)
        .timeSinceUndo($undoAction, perform: undo)
        .navigationTitle("Time since")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("Edit", systemImage: "pencil") { undoAction = nil; sheet = .edit }
                        .accessibilityIdentifier("timeSince.edit")
                    Button("Delete tracker", systemImage: "trash", role: .destructive) { undoAction = nil; showsDelete = true }
                } label: { Label("Tracker options", systemImage: "ellipsis") }
                .accessibilityIdentifier("timeSince.options")
            }
        }
        .sheet(item: $sheet) { selection in
            if let value = tracker {
                switch selection {
                case .edit: TimeSinceEditor(tracker: value)
                case .previousReset: PreviousResetSheet(tracker: value, onSave: recordPreviousReset)
                }
            }
        }
        .confirmationDialog("Move this tracker to Recently Deleted?", isPresented: $showsDelete, titleVisibility: .visible) {
            Button("Delete tracker", role: .destructive) {
                do { try RecentlyDeletedStore().moveTracker(id: trackerID, in: context); WidgetReloader.reloadAll(using: context); dismiss() }
                catch { self.error = error.localizedDescription }
            }
            Button("Cancel", role: .cancel) {}
        }
        .alert("Couldn't update tracker", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
            Button("Close", role: .cancel) {}
        } message: { Text(error ?? "") }
        .sensoryFeedback(.impact(weight: .light), trigger: feedback)
    }

    private func reset() {
        guard var value = tracker else { return }
        do {
            let change = try value.reset(at: .now)
            try TimeSinceStore().save(value, in: context)
            showUndo(.added(change))
            feedback += 1
        }
        catch { self.error = String(localized: "The reset wasn't saved. Check the device time and try again.") }
    }

    private func undo() {
        guard var value = tracker, let action = undoAction else { return }
        do {
            guard try action.undo(in: &value) else { undoAction = nil; return }
            try TimeSinceStore().save(value, in: context)
            undoAction = nil
            feedback += 1
        }
        catch { self.error = error.localizedDescription }
    }

    private func deleteReset(_ id: UUID) {
        guard var value = tracker, let event = value.deleteReset(id: id) else { return }
        do {
            try TimeSinceStore().save(value, in: context)
            showUndo(.deleted(event))
            feedback += 1
        } catch { self.error = error.localizedDescription }
    }

    private func showUndo(_ change: TimeSinceUndoAction.Change) {
        undoAction = TimeSinceUndoAction(trackerID: trackerID, change: change,
            lifetime: .seconds(voiceOverEnabled ? 20 : 6))
    }

    @ViewBuilder
    private func resetActions(_ value: TimeSinceTracker, now: Date) -> some View {
        Button(action: reset) {
            Label("Log a reset", systemImage: "arrow.counterclockwise")
                .frame(maxWidth: .infinity, minHeight: 44)
                .fixedSize(horizontal: false, vertical: true)
        }
            .buttonStyle(.bordered)
            .accessibilityIdentifier("timeSince.detail.reset")
            .disabled(now < value.currentStart)
        Button { undoAction = nil; sheet = .previousReset } label: {
            Text("Log a previous reset")
                .frame(maxWidth: .infinity, minHeight: 44)
                .fixedSize(horizontal: false, vertical: true)
        }
            .buttonStyle(.bordered)
            .accessibilityIdentifier("timeSince.detail.previous")
    }

    private func recordPreviousReset(at date: Date) throws {
        guard var value = tracker else { throw TimeSinceError.invalidTracker }
        let change = try value.recordPreviousReset(at: date)
        try TimeSinceStore().save(value, in: context)
        showUndo(.added(change))
        feedback += 1
    }
}
