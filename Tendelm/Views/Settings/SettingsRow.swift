import SwiftUI
import TendelmCore

struct SettingsIcon: View {
    let symbol: String
    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: 17, weight: .medium))
            .foregroundStyle(Color.kadoAccent)
            .frame(width: 32, height: 32)
            .accessibilityHidden(true)
    }
}

struct SettingsRow: View {
    let title: LocalizedStringKey
    let symbol: String
    var subtitle: LocalizedStringKey? = nil
    var body: some View {
        HStack(spacing: 12) {
            SettingsIcon(symbol: symbol)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).foregroundStyle(Color.kadoForeground)
                if let subtitle {
                    Text(subtitle).font(.subheadline).foregroundStyle(Color.kadoForegroundSecondary)
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .layoutPriority(1)
        }.frame(minHeight: 44)
            .accessibilityElement(children: .combine)
    }
}

struct ImportExportSettingsView: View {
    var body: some View {
        BackupSettingsContainer { sections in
            Form { sections }
                .tendelmSettingsPage()
                .navigationTitle("Import & export")
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct HabitCalendarSettingsView: View {
    var body: some View {
        Form { DayStartSection(); WeekStartSection() }
            .tendelmSettingsPage()
            .navigationTitle("Day & week")
            .navigationBarTitleDisplayMode(.inline)
    }
}

struct NotificationSettingsView: View {
    var body: some View {
        Form { NotificationsSection() }
            .tendelmSettingsPage()
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
    }
}

struct AdvancedSettingsView: View {
    var body: some View {
        Form { DevModeSection() }
            .tendelmSettingsPage()
            .navigationTitle("Advanced")
            .navigationBarTitleDisplayMode(.inline)
    }
}
