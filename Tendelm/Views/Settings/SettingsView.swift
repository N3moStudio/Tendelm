import SwiftUI
import SwiftData
import TendelmCore

struct SettingsView: View {
    @Environment(\.habitTheme) private var renderedTheme
    @Query(filter: #Predicate<HabitRecord> { $0.archivedAt != nil }) private var archived: [HabitRecord]
    @Query private var deleted: [RecentlyDeletedRecord]

    private var recoveryCount: Int { deleted.filter { $0.expiresAt > .now }.count }
    private var recoverySubtitle: LocalizedStringKey? {
        guard recoveryCount > 0 else { return nil }
        return recoveryCount == 1 ? "1 item" : "\(recoveryCount) items"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Make it yours") {
                    NavigationLink { AppearanceView() } label: {
                        SettingsRow(title: "Appearance", symbol: "paintpalette", subtitle: renderedTheme.name)
                    }.accessibilityIdentifier(AccessibilityID.Settings.appearanceRow)
                }.listRowBackground(Color.kadoBackgroundSecondary)
                Section("Your habits") {
                    NavigationLink { HabitCalendarSettingsView() } label: {
                        SettingsRow(title: "Day & week", symbol: "calendar")
                    }.accessibilityIdentifier("settings.calendar")
                    NavigationLink { NotificationSettingsView() } label: {
                        SettingsRow(title: "Notifications", symbol: "bell")
                    }.accessibilityIdentifier("settings.notifications")
                }.listRowBackground(Color.kadoBackgroundSecondary)
                Section {
                    NavigationLink { ArchivedHabitsView() } label: {
                        SettingsRow(title: "Archived habits", symbol: "archivebox", subtitle: archived.isEmpty ? nil : "\(archived.count) saved")
                    }.accessibilityIdentifier(AccessibilityID.Settings.archivedRow)
                    NavigationLink { RecentlyDeletedView() } label: {
                        SettingsRow(title: "Recently Deleted", symbol: "trash", subtitle: recoverySubtitle)
                    }.accessibilityIdentifier("settings.recentlyDeleted")
                    NavigationLink { ImportExportSettingsView() } label: {
                        SettingsRow(title: "Import & export", symbol: "externaldrive")
                    }.accessibilityIdentifier("settings.importExport")
                    NavigationLink { PrivacyResetView() } label: {
                        SettingsRow(title: "Privacy & reset", symbol: "hand.raised")
                    }.accessibilityIdentifier("settings.privacy")
                } header: { Text("Your data") }
                footer: { Text("Saved on this device. You're in control of what stays.") }
                .listRowBackground(Color.kadoBackgroundSecondary)
                Section("About") {
                    NavigationLink {
                        Form { SupportSection() }
                            .scrollContentBackground(.hidden).background(Color.kadoBackground)
                            .navigationTitle("About Tendelm").navigationBarTitleDisplayMode(.inline)
                    } label: { SettingsRow(title: "About Tendelm", symbol: "info.circle") }
                    NavigationLink { AdvancedSettingsView() } label: {
                        SettingsRow(title: "Advanced", symbol: "wrench.and.screwdriver")
                    }.accessibilityIdentifier("settings.advanced")
                }.listRowBackground(Color.kadoBackgroundSecondary)
                Section {} footer: {
                    Text("Tendelm · room to grow")
                        .font(.footnote).foregroundStyle(Color.kadoForegroundTertiary)
                        .frame(maxWidth: .infinity).padding(.vertical, 12)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.kadoBackground.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
