import SwiftUI
import TendelmCore

struct PreviousResetSheet: View {
    let tracker: TimeSinceTracker
    let onSave: (Date) throws -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var date = Date(timeIntervalSince1970: floor(Date.now.timeIntervalSince1970 / 60) * 60)
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("When", selection: $date, in: ...Date.now, displayedComponents: [.date, .hourAndMinute])
                        .accessibilityIdentifier("timeSince.previous.date")
                } footer: {
                    Text("Choose when it happened. Later resets stay in your history.")
                }
                .listRowBackground(Color.kadoBackgroundSecondary)
                if date < tracker.startedAt {
                    Text("This also moves the tracker's start back to this date.")
                        .font(.footnote).foregroundStyle(Color.kadoForegroundSecondary)
                        .listRowBackground(Color.kadoBackgroundSecondary)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.kadoBackground)
            .navigationTitle("Log a previous reset")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Log reset") {
                        do { try onSave(date); dismiss() }
                        catch TimeSinceError.resetMustBeInPast { error = "Choose a time that has already happened." }
                        catch TimeSinceError.duplicateReset { error = "A reset is already recorded at this time." }
                        catch { self.error = "The reset couldn't be saved. Please try again." }
                    }
                    .accessibilityIdentifier("timeSince.previous.save")
                }
            }
            .alert("Couldn't log reset", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
                Button("OK", role: .cancel) {}
            } message: { Text(error ?? "") }
        }
    }
}
