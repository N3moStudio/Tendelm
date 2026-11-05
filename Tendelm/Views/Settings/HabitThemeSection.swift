import SwiftUI
import TendelmCore

/// Each row chooses one palette. The dots are previews, not extra settings.
struct HabitThemeSection: View {
    @AppStorage(HabitThemeDefaults.key, store: HabitThemeDefaults.sharedDefaults)
    private var theme: HabitTheme = HabitThemeDefaults.defaultValue

    var body: some View {
        Section {
            ForEach(HabitTheme.allCases, id: \.self) { option in
                Button {
                    theme = option
                } label: {
                    HStack(spacing: 12) {
                        Text(option.name).foregroundStyle(Color.kadoForeground)
                        Spacer(minLength: 8)
                        HStack(spacing: 4) {
                            ForEach([HabitColor.orange, .green, .blue], id: \.self) { color in
                                Circle().fill(color.color(in: option)).frame(width: 12, height: 12)
                            }
                        }
                        .accessibilityHidden(true)
                        Image(systemName: "checkmark")
                            .fontWeight(.semibold).foregroundStyle(Color.kadoAccent)
                            .opacity(option == theme ? 1 : 0)
                    }
                    .frame(minHeight: 32)
                    .contentShape(Rectangle())
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(option.name))
                .accessibilityAddTraits(option == theme ? [.isButton, .isSelected] : .isButton)
                .accessibilityIdentifier(AccessibilityID.Settings.habitThemeRow(option.rawValue))
            }
        } header: {
            Text("Color palette").foregroundStyle(Color.kadoForegroundSecondary)
        } footer: {
            Text("Changes the colors of your habits and trackers. The dots are previews; choose an individual color when editing a habit or tracker.")
                .foregroundStyle(Color.kadoForegroundSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .listRowBackground(Color.kadoBackgroundSecondary)
    }
}

extension HabitTheme {
    var name: LocalizedStringKey {
        switch self {
        case .kado: "Tendelm"
        case .classic: "Classic"
        case .muted: "Muted"
        case .vivid: "Vivid"
        case .autumn: "Autumn"
        case .monochromeSage: "Sage"
        }
    }
}

#Preview {
    Form { HabitThemeSection() }
        .scrollContentBackground(.hidden)
        .background(Color.kadoBackground)
}
