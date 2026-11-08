import SwiftUI
import TendelmCore

struct PrivacyResetView: View {
    @Environment(\.eraseAllTendelmData) private var erase
    @State private var confirming = false
    @State private var error: String?

    var body: some View {
        Form {
            Section {
                Label("Saved on this device", systemImage: "iphone")
                Text("Tendelm doesn't need an account. Your habits and trackers stay on this device.")
                    .foregroundStyle(Color.kadoForegroundSecondary)
            }.listRowBackground(Color.kadoBackgroundSecondary)
            Section {
                Text("Updates keep your data. Importing a backup merges it with what's already saved.")
                Text("To start fresh, erase the saved data here before importing a different backup.")
                    .foregroundStyle(Color.kadoForegroundSecondary)
            } header: { Text("Updates & restores") }
            .listRowBackground(Color.kadoBackgroundSecondary)
            Section {
                Button("Erase all data", systemImage: "trash", role: .destructive) { confirming = true }
                    .frame(minHeight: 44).accessibilityIdentifier("settings.erase")
                    .alert("Erase all Tendelm data?", isPresented: $confirming) {
                        Button("Erase all data", role: .destructive) {
                            do { try erase() } catch { self.error = error.localizedDescription }
                        }.accessibilityIdentifier("settings.eraseConfirm")
                        Button("Cancel", role: .cancel) {}
                    } message: { Text("This also empties Recently Deleted. It cannot be undone. Export a backup first if you want to keep anything.") }
            } header: { Text("Start fresh") }
            footer: {
                Text("Permanently removes habits, history, trackers, Recently Deleted and app settings. Backups saved in Files and iOS permissions stay unchanged.")
            }
            .listRowBackground(Color.kadoBackgroundSecondary)
        }
        .tendelmSettingsPage()
        .navigationTitle("Privacy & reset")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Reset not complete", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
            Button("OK", role: .cancel) {}
        } message: { Text(error ?? "") }
    }
}
