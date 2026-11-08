import Foundation
import SwiftUI
import Testing
@testable import Tendelm

@MainActor
struct SettingsPresentationTests {
    @Test func compactOrdinaryTypeLeavesAccessibilityUnchanged() {
        #expect(SettingsTypography.compact(.xSmall) == .xSmall)
        #expect(SettingsTypography.compact(.large) == .medium)
        #expect(SettingsTypography.compact(.xxxLarge) == .xxLarge)
        for size in [DynamicTypeSize.accessibility1, .accessibility2, .accessibility3, .accessibility4, .accessibility5] {
            #expect(SettingsTypography.compact(size) == size)
        }
    }

    @Test func surfaceReadDoesNotMigrateOrResetExistingChoices() throws {
        let name = "settings-presentation-tests.\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        #expect(SettingsSurfaceDefaults.surface(in: defaults) == .solid)
        #expect(defaults.object(forKey: SettingsSurfaceDefaults.key) == nil)
        defaults.set("dark", forKey: "personal.appearance")
        defaults.set("autumn", forKey: "kado.habitTheme")
        defaults.set("futureSurface", forKey: SettingsSurfaceDefaults.key)
        #expect(SettingsSurfaceDefaults.surface(in: defaults) == .solid)
        #expect(defaults.string(forKey: SettingsSurfaceDefaults.key) == "futureSurface")
        defaults.set(SettingsSurface.liquidGlass.rawValue, forKey: SettingsSurfaceDefaults.key)
        #expect(SettingsSurfaceDefaults.surface(in: defaults) == .liquidGlass)
        #expect(defaults.string(forKey: "personal.appearance") == "dark")
        #expect(defaults.string(forKey: "kado.habitTheme") == "autumn")
    }

    @Test func transparencyRespectsAccessibilityPreferences() {
        #expect(SettingsSurface.allCases == [.solid, .liquidGlass])
        #expect(!SettingsSurface.solid.allowsTransparency(reduceTransparency: false, increasedContrast: false))
        #expect(SettingsSurface.liquidGlass.allowsTransparency(reduceTransparency: false, increasedContrast: false))
        #expect(!SettingsSurface.liquidGlass.allowsTransparency(reduceTransparency: true, increasedContrast: false))
        #expect(!SettingsSurface.liquidGlass.allowsTransparency(reduceTransparency: false, increasedContrast: true))
    }
}
