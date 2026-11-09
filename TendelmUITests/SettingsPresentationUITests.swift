import XCTest

final class SettingsPresentationUITests: TendelmUITestCase {
    @MainActor
    func testAppearanceChoicesPreserveNavigationAndPersist() {
        var app = launchApp(seedProduction: true)
        tapTab(.settings, in: app)
        capture(app, "settings-kit-overview")
        openSettingsPage(AccessibilityID.Settings.appearanceRow, in: app)
        let muted = app.buttons[AccessibilityID.Settings.habitThemeRow("muted")].firstMatch
        scrollTo(muted, in: app)
        muted.tap()
        XCTAssertTrue(muted.isSelected)
        XCTAssertTrue(app.navigationBars["Appearance"].exists)
        capture(app, "settings-muted")
        tapTab(.today, in: app)
        waitForTodayRows(in: app)
        capture(app, "today-muted")
        tapTab(.settings, in: app)
        XCTAssertTrue(app.navigationBars["Appearance"].exists, "Palette changes must keep the navigation stack.")
        XCTAssertTrue(muted.isSelected)
        let sage = app.buttons[AccessibilityID.Settings.habitThemeRow("monochromeSage")].firstMatch
        scrollTo(sage, in: app)
        sage.tap()
        XCTAssertFalse(app.buttons["appearance.surface.solid"].exists)
        capture(app, "settings-sage")
        app.terminate()
        app = launchApp(resetState: false)
        openSettingsPage(AccessibilityID.Settings.appearanceRow, in: app)
        let savedSage = app.buttons[AccessibilityID.Settings.habitThemeRow("monochromeSage")].firstMatch
        scrollTo(savedSage, in: app)
        XCTAssertTrue(savedSage.isSelected)
        goBack(in: app)
        XCTAssertTrue(app.navigationBars["Settings"].exists)
        openSettingsPage("settings.importExport", in: app)
        XCTAssertTrue(app.buttons["backup.paste"].exists)
        capture(app, "settings-kit-import")
    }

    @MainActor
    func testRetiredPaletteOpensAsTendelmWithoutExtraChoices() {
        let app = launchApp(habitTheme: "vivid")
        openSettingsPage(AccessibilityID.Settings.appearanceRow, in: app)
        XCTAssertTrue(app.buttons[AccessibilityID.Settings.habitThemeRow("kado")].firstMatch.isSelected)
        XCTAssertFalse(app.buttons[AccessibilityID.Settings.habitThemeRow("vivid")].exists)
        XCTAssertFalse(app.buttons[AccessibilityID.Settings.habitThemeRow("classic")].exists)
    }
}
