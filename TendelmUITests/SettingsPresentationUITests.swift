import XCTest

final class SettingsPresentationUITests: TendelmUITestCase {
    @MainActor
    func testAppearanceChoicesPreserveNavigationAndPersist() {
        var app = launchApp(seedProduction: true)
        tapTab(.settings, in: app)
        capture(app, "settings-kit-overview")
        openSettingsPage(AccessibilityID.Settings.appearanceRow, in: app)
        let classic = app.buttons[AccessibilityID.Settings.habitThemeRow("classic")].firstMatch
        scrollTo(classic, in: app)
        classic.tap()
        let glass = app.buttons["appearance.surface.liquidGlass"]
        scrollTo(glass, in: app)
        glass.tap()
        XCTAssertTrue(glass.isSelected)
        XCTAssertTrue(app.navigationBars["Appearance"].exists)
        capture(app, "settings-kit-glass")
        tapTab(.today, in: app)
        waitForTodayRows(in: app)
        tapTab(.settings, in: app)
        XCTAssertTrue(app.navigationBars["Appearance"].exists, "Changing appearance must keep the navigation stack.")
        XCTAssertTrue(glass.isSelected)
        scrollBackTo(classic, in: app)
        XCTAssertTrue(classic.isSelected)
        let sage = app.buttons[AccessibilityID.Settings.habitThemeRow("monochromeSage")].firstMatch
        scrollTo(sage, in: app)
        sage.tap()
        scrollTo(glass, in: app)
        XCTAssertTrue(glass.isSelected, "Palette selection must not reset the independent surface choice.")
        capture(app, "settings-kit-palettes-and-surface")
        app.terminate()
        app = launchApp(resetState: false)
        openSettingsPage(AccessibilityID.Settings.appearanceRow, in: app)
        let savedSage = app.buttons[AccessibilityID.Settings.habitThemeRow("monochromeSage")].firstMatch
        scrollTo(savedSage, in: app)
        XCTAssertTrue(savedSage.isSelected)
        let savedGlass = app.buttons["appearance.surface.liquidGlass"]
        scrollTo(savedGlass, in: app)
        XCTAssertTrue(savedGlass.isSelected)
        app.buttons["appearance.surface.solid"].tap()
        XCTAssertTrue(app.buttons["appearance.surface.solid"].isSelected)
        goBack(in: app)
        XCTAssertTrue(app.navigationBars["Settings"].exists)
        openSettingsPage("settings.importExport", in: app)
        XCTAssertTrue(app.buttons["backup.paste"].exists)
        capture(app, "settings-kit-import")
    }
    @MainActor
    private func scrollBackTo(_ element: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<8 {
            if element.exists && element.isHittable { return }
            app.swipeDown(velocity: .slow)
        }
        XCTAssertTrue(element.exists && element.isHittable)
    }
}
