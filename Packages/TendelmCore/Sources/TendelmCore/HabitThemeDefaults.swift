import Foundation

/// Single source of truth for the "Habit colours" preference.
///
/// Mirrors ``WeekStartDefaults``: stored in `UserDefaults` rather than
/// on a `@Model` so the SwiftData — and therefore CloudKit Production
/// — schema stays untouched, and in the App Group suite because the
/// widget extension reads it too, to paint its tiles in the same
/// theme. Per-device, which suits a display preference: two devices
/// disagreeing changes how habits look there, never what they are.
nonisolated public enum HabitThemeDefaults {
    public static let key = "kado.habitTheme"

    public static let defaultValue: HabitTheme = .kado

    /// UserDefaults suite shared between the main app and the widget
    /// extension. Creating a suite object alone does not prove the app has
    /// access to that group. Sideloaded installs may have no group entitlement.
    nonisolated(unsafe) public static let sharedDefaults: UserDefaults = {
        let shared = UserDefaults(suiteName: SharedStore.appGroupID)
        guard SharedStore.appGroupContainerURL() != nil else {
            // Keep an earlier pick without overwriting an existing local pick.
            if UserDefaults.standard.object(forKey: key) == nil,
               let raw = shared?.string(forKey: key), HabitTheme(rawValue: raw) != nil {
                UserDefaults.standard.set(raw, forKey: key)
            }
            return .standard
        }
        return shared ?? .standard
    }()

    /// Reads the stored choice. An unset key, or a raw value written
    /// by a future build with more themes, both resolve to
    /// ``HabitTheme/kado`` rather than trapping.
    public static func theme(in defaults: UserDefaults = sharedDefaults) -> HabitTheme {
        defaults.string(forKey: key).flatMap(HabitTheme.init(rawValue:)) ?? defaultValue
    }

    /// Widgets use the same preference. Every Tendelm palette is included;
    /// the legacy supporter mirror cannot make a selected palette disappear.
    public static func renderedTheme(
        in defaults: UserDefaults = sharedDefaults,
        supporterDefaults: UserDefaults = SupporterDefaults.sharedDefaults
    ) -> HabitTheme {
        HabitTheme.effective(preferred: theme(in: defaults), in: supporterDefaults)
    }

    public static func setTheme(_ theme: HabitTheme, in defaults: UserDefaults = sharedDefaults) {
        defaults.set(theme.rawValue, forKey: key)
    }
}
