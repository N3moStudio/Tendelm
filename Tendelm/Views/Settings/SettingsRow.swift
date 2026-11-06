import SwiftUI
import TendelmCore

struct SettingsIcon: View {
    let symbol: String
    var body: some View {
        Image(systemName: symbol)
            .font(.body.weight(.medium))
            .foregroundStyle(Color.kadoAccent)
            .frame(width: 34, height: 36)
            .background(Color.kadoAccentTint, in: RoundedRectangle(cornerRadius: 10))
            .accessibilityHidden(true)
    }
}

struct SettingsRow: View {
    let title: LocalizedStringKey
    let symbol: String
    var body: some View {
        HStack(spacing: 12) {
            SettingsIcon(symbol: symbol)
            Text(title).foregroundStyle(Color.kadoForeground)
                .fixedSize(horizontal: false, vertical: true)
        }.frame(minHeight: 44)
    }
}

struct ImportExportSettingsView: View {
    var body: some View {
        BackupSettingsContainer { sections in
            Form { sections }
                .scrollContentBackground(.hidden)
                .background(Color.kadoBackground)
                .navigationTitle("Import & export")
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct HabitCalendarSettingsView: View {
    var body: some View {
        Form { DayStartSection(); WeekStartSection() }
            .scrollContentBackground(.hidden)
            .background(Color.kadoBackground)
            .navigationTitle("Day & week")
            .navigationBarTitleDisplayMode(.inline)
    }
}

struct NotificationSettingsView: View {
    var body: some View {
        Form { NotificationsSection() }
            .scrollContentBackground(.hidden)
            .background(Color.kadoBackground)
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
    }
}

struct AdvancedSettingsView: View {
    var body: some View {
        Form { DevModeSection() }
            .scrollContentBackground(.hidden)
            .background(Color.kadoBackground)
            .navigationTitle("Advanced")
            .navigationBarTitleDisplayMode(.inline)
    }
}
