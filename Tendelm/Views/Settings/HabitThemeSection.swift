import SwiftUI
import TendelmCore

/// Each row chooses one palette. The dots are previews, not extra settings.
struct HabitThemeSection: View {
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
                        theme = option
                    } label: {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                            HStack(spacing: 4) {
                                ForEach([HabitColor.orange, .green, .blue], id: \.self) { color in
                                    Circle().fill(color.color(in: option)).frame(width: 12, height: 12)
                                }
                            }
                            .accessibilityHidden(true)
                            Spacer(minLength: 4)
                            Image(systemName: option == theme.current ? "checkmark.circle.fill" : "circle")
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
                            .strokeBorder(option == theme.current ? Color.kadoAccent.inPalette(option) : Color.kadoDivider.inPalette(option), lineWidth: option == theme.current ? 2 : 1))
                        .contentShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .environment(\.habitTheme, option)
                    .buttonStyle(.plain)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Text(option.name))
                    .accessibilityAddTraits(option == theme.current ? [.isButton, .isSelected] : .isButton)
                    .accessibilityIdentifier(AccessibilityID.Settings.habitThemeRow(option.rawValue))
                }
            }.padding(.vertical, 8)
        } header: {
            Text("Color palette").foregroundStyle(Color.kadoForegroundSecondary)
        } footer: {
            Text("Changes page colors, accents, habits and trackers. The dots preview each palette. Your individual habit colors stay saved.")
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
