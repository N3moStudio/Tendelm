import SwiftUI
import SwiftData
import TendelmCore

struct TimeSinceDetailView: View {
    let trackerID: UUID
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var records: [TimeSinceRecord]
    @State private var showsEdit = false
    @State private var showsDelete = false
    @State private var error: String?
    @State private var feedback = 0

    private var tracker: TimeSinceTracker? { records.first { $0.id == trackerID }?.snapshot }

    var body: some View {
        Group {
            if let value = tracker {
                List {
                    Section {
                        VStack(alignment: .leading, spacing: 16) {
                            Text(value.name).font(.title2.weight(.semibold))
                                .fixedSize(horizontal: false, vertical: true)
                            ElapsedTimeLabel(start: value.currentStart, showsSeconds: true)
                            Text("Since \(value.currentStart.formatted(date: .abbreviated, time: .shortened))")
                                .font(.footnote).foregroundStyle(Color.kadoForegroundSecondary)
                            Button("Log a reset", systemImage: "arrow.counterclockwise") { reset() }
                                .buttonStyle(.bordered).frame(minHeight: 44)
                                .accessibilityIdentifier("timeSince.detail.reset")
                            if !value.resets.isEmpty {
                                Button("Undo last reset", systemImage: "arrow.uturn.backward") { undo() }
                                    .frame(minHeight: 44)
                                    .accessibilityIdentifier("timeSince.detail.undo")
                            }
                        }.padding(.vertical, 8)
                    } footer: {
                        Text("A reset records what happened. Your earlier time still counts.")
                    }
                    .listRowBackground(Color.kadoBackgroundSecondary)
                    Section("History") {
                        ForEach(value.orderedResets.reversed()) { event in
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Reset logged")
                                Text(event.date, format: .dateTime.day().month().year().hour().minute().second())
                                    .font(.footnote).foregroundStyle(Color.kadoForegroundSecondary)
                            }
                            .accessibilityIdentifier("timeSince.history.\(event.id)")
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Started")
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
        .navigationTitle("Time since")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("Edit", systemImage: "pencil") { showsEdit = true }
                        .accessibilityIdentifier("timeSince.edit")
                    Button("Delete tracker", systemImage: "trash", role: .destructive) { showsDelete = true }
                } label: { Label("Tracker options", systemImage: "ellipsis") }
                .accessibilityIdentifier("timeSince.options")
            }
        }
        .sheet(isPresented: $showsEdit) { if let value = tracker { TimeSinceEditor(tracker: value) } }
        .confirmationDialog("Delete this tracker and its history?", isPresented: $showsDelete, titleVisibility: .visible) {
            Button("Delete tracker", role: .destructive) {
                do { try TimeSinceStore().delete(id: trackerID, in: context); dismiss() }
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
        do { try value.reset(at: .now); try TimeSinceStore().save(value, in: context); feedback += 1 }
        catch { self.error = String(localized: "The reset wasn't saved. Check the device time and try again.") }
    }

    private func undo() {
        guard var value = tracker else { return }
        value.undoLastReset()
        do { try TimeSinceStore().save(value, in: context); feedback += 1 }
        catch { self.error = error.localizedDescription }
    }
}
