import SwiftUI
import TendelmCore

/// Each row chooses one palette. The dots are previews, not extra settings.
struct HabitThemeSection: View {
    var isAppPalette = false
    @AppStorage("personal.appPalette") private var appPalette = ""
    private var selected: HabitTheme {
        isAppPalette ? (HabitTheme(rawValue: appPalette)?.current ?? theme.current) : theme.current
    }
    @Environment(\.dynamicTypeSize) private var size
    @AppStorage(HabitThemeDefaults.key, store: HabitThemeDefaults.sharedDefaults)
    private var theme: HabitTheme = HabitThemeDefaults.defaultValue

    var body: some View {
        Section {
            LazyVGrid(columns: size.isAccessibilitySize
                      ? [GridItem(.flexible())]
                      : [GridItem(.adaptive(minimum: 140), spacing: 12)], spacing: 12) {
                ForEach(HabitTheme.selectable, id: \.self) { option in
                    Button {
                        if isAppPalette {
                            appPalette = option.rawValue
                        } else {
                            // Freeze the inherited app palette before changing habit colors.
                            if appPalette.isEmpty { appPalette = theme.current.rawValue }
                            theme = option
                        }
                    } label: {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                            if isAppPalette {
                                VStack(alignment: .leading, spacing: 4) {
                                    RoundedRectangle(cornerRadius: 3).fill(Color.kadoAccent.inPalette(option)).frame(width: 30, height: 5)
                                    RoundedRectangle(cornerRadius: 4).fill(Color.kadoBackgroundSecondary.inPalette(option)).frame(height: 16)
                                    RoundedRectangle(cornerRadius: 3).fill(Color.kadoForegroundSecondary.inPalette(option)).frame(width: 22, height: 3)
                                }.frame(width: 54).accessibilityHidden(true)
                            } else {
                            HStack(spacing: 4) {
                                ForEach([HabitColor.orange, .green, .blue], id: \.self) { color in
                                    Circle().fill(color.color(in: option)).frame(width: 12, height: 12)
                                }
                            }
                            .accessibilityHidden(true)
                            }
                            Spacer(minLength: 4)
                            Image(systemName: option == selected ? "checkmark.circle.fill" : "circle")
                                .fontWeight(.semibold).foregroundStyle(Color.kadoAccent.inPalette(option))
                                .accessibilityHidden(true)
                            }
                            Text(option.name).font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.kadoForeground.inPalette(option))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, minHeight: 88, alignment: .leading)
                        .background(Color.kadoBackground.inPalette(option), in: RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(option == selected ? Color.kadoAccent.inPalette(option) : Color.kadoDivider.inPalette(option), lineWidth: option == selected ? 2 : 1))
                        .contentShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .environment(\.habitTheme, option)
                    .buttonStyle(.plain)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Text(option.name))
                    .accessibilityAddTraits(option == selected ? [.isButton, .isSelected] : .isButton)
                    .accessibilityIdentifier(isAppPalette ? "settings.appPalette.\(option.rawValue)" : AccessibilityID.Settings.habitThemeRow(option.rawValue))
                }
            }.padding(.vertical, 8)
        } header: {
            Text(isAppPalette ? "App theme" : "Habit colors").foregroundStyle(Color.kadoForegroundSecondary)
        } footer: {
            Text(isAppPalette ? "Changes backgrounds, cards, text and accents throughout the app." : "Changes habit and tracker colors independently. Your individual color choices stay saved.")
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
