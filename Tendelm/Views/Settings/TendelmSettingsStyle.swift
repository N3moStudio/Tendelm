import SwiftUI
import TendelmCore

// Presentation patterns adapted from Native Settings Kit 0.1.0.
// See UI/NativeSettingsKit/PROVENANCE.md and retained LICENSES.
// Host colors, preference ownership and navigation stay with Tendelm.
enum SettingsSurface: String, CaseIterable {
    case solid, liquidGlass

    var title: LocalizedStringKey {
        switch self {
        case .solid: "Solid"
        case .liquidGlass: "Liquid Glass"
        }
    }

    func allowsTransparency(reduceTransparency: Bool, increasedContrast: Bool) -> Bool {
        self == .liquidGlass && !reduceTransparency && !increasedContrast
    }
}

enum SettingsSurfaceDefaults {
    static let key = "personal.settingsSurface"
    static func surface(in defaults: UserDefaults = .standard) -> SettingsSurface {
        // Reading a future/unknown value must not overwrite it with a fallback.
        defaults.string(forKey: key).flatMap(SettingsSurface.init(rawValue:)) ?? .solid
    }
}

enum SettingsTypography {
    static func compact(_ size: DynamicTypeSize) -> DynamicTypeSize {
        guard !size.isAccessibilitySize else { return size }
        let sizes: [DynamicTypeSize] = [.xSmall, .small, .medium, .large, .xLarge, .xxLarge, .xxxLarge]
        guard let index = sizes.firstIndex(of: size) else { return size }
        return sizes[max(0, index - 1)]
    }
}

private struct SettingsTypographyAppliedKey: EnvironmentKey {
    static let defaultValue = false
}

private extension EnvironmentValues {
    var settingsTypographyApplied: Bool {
        get { self[SettingsTypographyAppliedKey.self] }
        set { self[SettingsTypographyAppliedKey.self] = newValue }
    }
}

private struct SettingsAppearanceModifier: ViewModifier {
    @Environment(\.dynamicTypeSize) private var size
    @Environment(\.settingsTypographyApplied) private var alreadyApplied

    func body(content: Content) -> some View {
        content
            .fontDesign(.rounded)
            .dynamicTypeSize(alreadyApplied ? size : SettingsTypography.compact(size))
            .environment(\.settingsTypographyApplied, true)
    }
}

private struct SettingsPageModifier: ViewModifier {
    @AppStorage(SettingsSurfaceDefaults.key) private var surfaceRaw = SettingsSurface.solid.rawValue
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.colorScheme) private var scheme

    func body(content: Content) -> some View {
        let surface = SettingsSurface(rawValue: surfaceRaw) ?? .solid
        let glass = surface.allowsTransparency(reduceTransparency: reduceTransparency, increasedContrast: contrast == .increased)
        content
            .listStyle(.insetGrouped)
            .listRowSpacing(0)
            .listSectionSpacing(24)
            .environment(\.defaultMinListRowHeight, 52)
            .scrollContentBackground(.hidden)
            .background(Color.kadoBackground.ignoresSafeArea())
            // Leave control foregrounds semantic so destructive and disabled
            // actions retain their native warning/dimmed appearance.
            .tint(Color.kadoAccent)
            // iOS owns its navigation material (glass on supported systems,
            // native material on older ones). Content rows remain opaque.
            .toolbarBackground(Color.kadoBackgroundSecondary, for: .navigationBar)
            .toolbarBackground(glass ? .automatic : .visible, for: .navigationBar)
            .toolbarColorScheme(scheme, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
    }
}

extension View {
    func tendelmSettingsAppearance() -> some View { modifier(SettingsAppearanceModifier()) }
    func tendelmSettingsPage() -> some View { modifier(SettingsPageModifier()) }
}

struct SettingsIdentityLabel: View {
    @Environment(\.habitTheme) private var theme
    @Environment(\.dynamicTypeSize) private var size
    @AppStorage(SettingsSurfaceDefaults.key) private var surfaceRaw = SettingsSurface.solid.rawValue

    var body: some View {
        let layout = size.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12))
            : AnyLayout(HStackLayout(alignment: .center, spacing: 18))
        layout {
            Image("AppIconPreviewTendelm")
                .resizable().scaledToFit().frame(width: 70, height: 70)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 6) {
                Text("MAKE IT YOURS").font(.caption.weight(.semibold)).tracking(1.2)
                    .foregroundStyle(Color.kadoAccent)
                Text("Room to grow.").font(.title2.weight(.bold))
                    .foregroundStyle(Color.kadoForeground)
                (Text(theme.name) + Text(" · ") + Text((SettingsSurface(rawValue: surfaceRaw) ?? .solid).title))
                    .font(.subheadline).foregroundStyle(Color.kadoForegroundSecondary)
            }.fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 16)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Appearance")
        .accessibilityValue(Text(theme.name) + Text(" · ") + Text((SettingsSurface(rawValue: surfaceRaw) ?? .solid).title))
    }
}

struct SettingsSurfaceSection: View {
    @AppStorage(SettingsSurfaceDefaults.key) private var surfaceRaw = SettingsSurface.solid.rawValue
    private var surface: SettingsSurface { SettingsSurface(rawValue: surfaceRaw) ?? .solid }

    var body: some View {
        Section {
            ForEach(SettingsSurface.allCases, id: \.self) { option in
                Button { surfaceRaw = option.rawValue } label: {
                    HStack {
                        Text(option.title).fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 8)
                        Image(systemName: "checkmark").fontWeight(.semibold)
                            .opacity(surface == option ? 1 : 0).accessibilityHidden(true)
                    }.frame(minHeight: 44).contentShape(Rectangle())
                }
                .foregroundStyle(Color.kadoForeground)
                .accessibilityAddTraits(surface == option ? .isSelected : [])
                .accessibilityIdentifier("appearance.surface.\(option.rawValue)")
            }
        } header: { Text("Surface") }
        footer: { Text("Changes Settings bars. Lists stay solid for readability. Reduce Transparency and Increase Contrast use solid bars.") }
        .listRowBackground(Color.kadoBackgroundSecondary)
    }
}
