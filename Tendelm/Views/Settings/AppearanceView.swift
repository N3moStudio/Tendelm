import SwiftUI
import TendelmCore

/// Display appearance and habit/trackers' color palette are separate choices.
struct AppearanceView: View {
    @AppStorage("personal.appearance") private var appearance: AppAppearance = .system
    @Environment(\.appearanceAnnouncement) private var appearanceAnnouncement

    var body: some View {
        Form {
            Section("Display") {
                Picker("Appearance", selection: $appearance) {
                    Text("System").tag(AppAppearance.system)
                    Text("Light").tag(AppAppearance.light)
                    Text("Dark").tag(AppAppearance.dark)
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("appearance.display")
            }
            .listRowBackground(Color.kadoBackgroundSecondary)
            HabitThemeSection()
        }
        .tendelmSettingsPage()
        .tendelmSettingsAppearance()
        .navigationTitle("Appearance")
        // Whichever way the user got here — Today's card or Settings —
        // they have found the screen, so Today stops announcing it.
        .onAppear { appearanceAnnouncement.retire() }
    }
}

#Preview("Appearance") {
    NavigationStack {
        AppearanceView()
    }
}

#Preview("Palettes") {
    NavigationStack {
        AppearanceView()
    }
    .environment(\.supporterPack, MockSupporterPackStore(isSupporter: true))
}

#Preview("Dark") {
    NavigationStack {
        AppearanceView()
    }
    .environment(\.supporterPack, MockSupporterPackStore(isSupporter: true))
    .preferredColorScheme(.dark)
}
