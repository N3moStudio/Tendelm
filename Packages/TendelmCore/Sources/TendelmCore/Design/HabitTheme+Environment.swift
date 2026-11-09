import SwiftUI
import UIKit

/// Color appearance is scoped to each view hierarchy, including widgets.
/// Bridging makes UIKit-backed colors follow the same choice as SwiftUI views.
public struct HabitThemeTrait: UITraitDefinition {
    public static let defaultValue = HabitTheme.kado
    public static let affectsColorAppearance = true
}

private struct HabitThemeKey: UITraitBridgedEnvironmentKey {
    static let defaultValue = HabitTheme.kado

    static func read(from traitCollection: UITraitCollection) -> HabitTheme {
        traitCollection[HabitThemeTrait.self]
    }

    static func write(to mutableTraits: inout UIMutableTraits, value: HabitTheme) {
        mutableTraits[HabitThemeTrait.self] = value
    }
}

public extension EnvironmentValues {
    /// SwiftUI state remains independent of UIKit's inherited trait defaults.
    @Entry var habitTheme: HabitTheme = HabitThemeDefaults.defaultValue

    /// UIKit's window trait is also visible during SwiftUI color resolution.
    var appPaletteTrait: HabitTheme {
        get { self[HabitThemeKey.self] }
        set { self[HabitThemeKey.self] = newValue }
    }
}
