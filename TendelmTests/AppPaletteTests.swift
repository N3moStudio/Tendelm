import SwiftUI
import UIKit
import Testing
import TendelmCore

@MainActor
struct AppPaletteTests {
    @Test func fourDistinctPalettesResolveInBothAppearances() {
        #expect(HabitTheme.selectable == [.kado, .muted, .autumn, .monochromeSage])
        for dark in [false, true] {
            let backgrounds = HabitTheme.selectable.map { rgba(.kadoBackground, $0, dark) }
            let accents = HabitTheme.selectable.map { rgba(.kadoAccent, $0, dark) }
            #expect(Set(backgrounds).count == 4)
            #expect(Set(accents).count == 4)
            for theme in HabitTheme.selectable {
                for surface in [Color.kadoBackground, .kadoBackgroundSecondary] {
                    for text in [Color.kadoForeground, .kadoForegroundSecondary, .kadoAccent] {
                        let a = luminance(rgba(text, theme, dark))
                        let b = luminance(rgba(surface, theme, dark))
                        #expect((max(a, b) + 0.05) / (min(a, b) + 0.05) >= 4.5,
                                "Readable text in \(theme), dark: \(dark)")
                    }
                }
            }
        }
    }

    @Test func retiredChoicesRemainDecodableWithoutRewritingStorage() throws {
        let name = "palette-compatibility.\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        for legacy in ["classic", "vivid"] {
            defaults.set(legacy, forKey: HabitThemeDefaults.key)
            #expect(HabitThemeDefaults.renderedTheme(in: defaults) == .kado)
            #expect(defaults.string(forKey: HabitThemeDefaults.key) == legacy)
            #expect(HabitTheme(rawValue: legacy) != nil)
        }
    }

    @Test func unscheduledCalendarCellsStayQuieterThanScoredCells() {
        for theme in HabitTheme.selectable {
            for dark in [false, true] {
                let empty = lightness(rgba(.kadoCalendarEmpty, theme, dark))
                for color in HabitColor.allCases {
                    let scored = lightness(rgba(color.tint(.tileLight, in: theme), theme, dark))
                    #expect(dark ? empty < scored : empty > scored,
                            "Unscheduled day should be quiet: \(theme), \(color), dark: \(dark)")
                }
            }
        }
    }

    private func lightness(_ rgba: [Double]) -> Double {
        Oklab(srgbRed: rgba[0], green: rgba[1], blue: rgba[2]).l
    }

    private func rgba(_ color: Color, _ theme: HabitTheme, _ dark: Bool) -> [Double] {
        let traits = UITraitCollection { traits in
            traits.userInterfaceStyle = dark ? .dark : .light
            traits[HabitThemeTrait.self] = theme
        }
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(color).resolvedColor(with: traits).getRed(&r, green: &g, blue: &b, alpha: &a)
        return [Double(r), Double(g), Double(b), Double(a)]
    }

    private func luminance(_ rgba: [Double]) -> Double {
        let linear = rgba.prefix(3).map { $0 <= 0.04045 ? $0 / 12.92 : pow(($0 + 0.055) / 1.055, 2.4) }
        return linear[0] * 0.2126 + linear[1] * 0.7152 + linear[2] * 0.0722
    }
}
