import SwiftUI
import SwiftData
import TendelmCore

struct TimeSinceEditor: View {
    let tracker: TimeSinceTracker?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @State private var name = ""
    @State private var start: Date = .now
    @State private var color: HabitColor = .green
    @State private var error: String?
    @FocusState private var nameFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("What are you stepping away from?", text: $name, axis: .vertical)
                        .focused($nameFocused)
                        .submitLabel(.done)
                        .onSubmit(save)
                        .accessibilityIdentifier("timeSince.name")
                } footer: {
                    Text("Give it a name. Your time starts now.")
                }
                Section {
                    DisclosureGroup("Start date & color") {
                        DatePicker("Started", selection: $start, in: ...latestStart, displayedComponents: [.date, .hourAndMinute])
                        HabitColorPicker(selection: $color)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.kadoBackground)
            .navigationTitle(tracker == nil ? "New tracker" : "Edit tracker")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(tracker == nil ? "Start" : "Save", action: save)
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .accessibilityIdentifier("timeSince.save")
                }
            }
            .onAppear {
                name = tracker?.name ?? ""
                start = tracker?.startedAt ?? .now
                color = tracker?.color ?? .green
                nameFocused = tracker == nil
            }
            .alert("Couldn't save tracker", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
                Button("Close", role: .cancel) {}
            } message: { Text(error ?? "") }
        }
    }

    private var latestStart: Date { min(.now, tracker?.orderedResets.first?.date ?? .now) }

    private func save() {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        var value = tracker ?? TimeSinceTracker(name: name)
        value.name = name
        value.startedAt = min(start, latestStart)
        value.color = color
        do {
            try TimeSinceStore().save(value, in: context)
            dismiss()
        } catch { self.error = error.localizedDescription }
    }
}
