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
    /// The habit colour theme views paint every `HabitColor` in.
    /// `TendelmApp` injects the stored choice at the root and each widget
    /// injects it from `HabitThemeDefaults`, so a switch in Settings
    /// re-renders every reader — which a global `HabitColor.color`
    /// read implicitly could not do without an `.id(...)` remount.
    var habitTheme: HabitTheme {
        get { self[HabitThemeKey.self] }
        set { self[HabitThemeKey.self] = newValue }
    }
}
