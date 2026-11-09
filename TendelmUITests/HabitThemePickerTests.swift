import XCTest
import UIKit

/// The Habit colours picker (#111) reaches the app-wide theme.
///
/// `HabitColorTests` sweeps what each theme paints; what a unit test
/// cannot see is whether a tap in Settings reaches the environment
/// every habit view reads, *live* — a theme that only lands on the
/// next launch would pass the unit suite. Also the one place the
/// picker and the recoloured screens get photographed, since the
/// build tooling cannot tap into Settings.
final class HabitThemePickerTests: TendelmUITestCase {

    private func themeRow(_ rawValue: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any)
            .matching(identifier: AccessibilityID.Settings.habitThemeRow(rawValue))
            .firstMatch
    }

    /// Settings → Appearance, where the picker lives.
    @MainActor
    private func openAppearance(in app: XCUIApplication) {
        tapTab(.settings, in: app)
        let row = app.descendants(matching: .any)[AccessibilityID.Settings.appearanceRow].firstMatch
        scrollTo(row, in: app)
        capture(app, "settings-appearance-row")
        row.tap()
    }

    @MainActor
    func testChoosingMutedRecoloursTheAppWithoutARelaunch() {
        let app = launchApp(seedProduction: true, seedForScreenshots: true)
        waitForTodayRows(in: app)
        let before = badgePixels(in: app)
        capture(app, "habit-theme-today-kado")

        openAppearance(in: app)
        let kado = themeRow("kado", in: app)
        let muted = themeRow("muted", in: app)
        scrollTo(muted, in: app)
        scrollClearOfTabBar(muted, in: app)
        XCTAssertTrue(kado.exists, "Settings should offer the Tendelm theme.")
        capture(app, "habit-theme-picker-kado")

        XCTAssertTrue(kado.isSelected, "Tendelm should be the theme a fresh install starts on.")
        muted.tap()
        let mutedSelected = expectation(for: NSPredicate(format: "isSelected == true"), evaluatedWith: muted)
        wait(for: [mutedSelected], timeout: 5)
        XCTAssertFalse(kado.isSelected, "Choosing Muted should deselect Tendelm.")
        capture(app, "habit-theme-picker-muted")

        tapTab(.overview, in: app)
        capture(app, "habit-theme-overview-muted")

        tapTab(.today, in: app)
        waitForTodayRows(in: app)
        capture(app, "habit-theme-today-muted")
        XCTAssertNotEqual(before, badgePixels(in: app), "The habit's painted badge must change, not only the Settings checkmark.")
    }

    @MainActor
    private func badgePixels(in app: XCUIApplication) -> Data? {
        RunLoop.current.run(until: Date().addingTimeInterval(0.6))
        let image = todayRows(in: app).firstMatch.screenshot().image
        guard let cg = image.cgImage else { return nil }
        // Only the leading badge: excludes text, counts, clocks and controls.
        let crop = CGRect(x: 0, y: 4 * image.scale, width: 38 * image.scale, height: 38 * image.scale)
        guard let badge = cg.cropping(to: crop) else { return nil }
        return UIImage(cgImage: badge).pngData()
    }

    @MainActor
    func testAppearanceAndPaletteSurviveRelaunch() {
        var app = launchApp(seedProduction: true, seedForScreenshots: true)
        openAppearance(in: app)
        let display = app.segmentedControls["appearance.display"]
        XCTAssertTrue(display.waitForExistence(timeout: 5))
        display.buttons["Light"].tap()
        let light = pagePixel(in: app)
        display.buttons["Dark"].tap()
        let dark = pagePixel(in: app)
        XCTAssertNotEqual(light, dark, "The page itself must change when Display changes.")
        let autumn = themeRow("autumn", in: app)
        scrollTo(autumn, in: app)
        autumn.tap()
        XCTAssertTrue(autumn.isSelected)
        capture(app, "appearance-dark-autumn")
        app.terminate()
        app = launchApp(resetState: false)
        openAppearance(in: app)
        XCTAssertTrue(app.segmentedControls["appearance.display"].buttons["Dark"].isSelected)
        XCTAssertTrue(themeRow("autumn", in: app).isSelected)
        XCTAssertNotEqual(dark, pagePixel(in: app), "Autumn changes the page color as well as the habit swatches.")
        app.segmentedControls["appearance.display"].buttons["Light"].tap()
        capture(app, "appearance-light-autumn")
        app.segmentedControls["appearance.display"].buttons["System"].tap()
        XCTAssertTrue(app.segmentedControls["appearance.display"].buttons["System"].isSelected)
    }

    @MainActor
    private func pagePixel(in app: XCUIApplication) -> Data? {
        RunLoop.current.run(until: Date().addingTimeInterval(0.6))
        let image = app.screenshot().image
        guard let cg = image.cgImage,
              let pixel = cg.cropping(to: CGRect(x: image.scale * 4, y: CGFloat(cg.height) / 2, width: 1, height: 1))
        else { return nil }
        return pixel.dataProvider?.data as Data?
    }

    /// A paid theme without the pack (#113) opens the pack instead of
    /// being picked. The routing is the half a unit test can't see:
    /// the destination sits on `AppearanceView`'s `Form`, and a
    /// `navigationDestination` in the wrong place is silently ignored.
    @MainActor
    func testEveryPaletteIsSelectableInPersonalEdition() {
        let app = launchApp(seedProduction: true, seedForScreenshots: true)
        openAppearance(in: app)
        var paintedPages = Set<Data>()
        for theme in ["muted", "autumn", "monochromeSage", "kado"] {
            let row = themeRow(theme, in: app)
            scrollTo(row, in: app)
            scrollClearOfTabBar(row, in: app)
            row.tap()
            let selected = expectation(for: NSPredicate(format: "isSelected == true"), evaluatedWith: row)
            wait(for: [selected], timeout: 5)
            let pixels = pagePixel(in: app)
            XCTAssertNotNil(pixels)
            if let pixels { paintedPages.insert(pixels) }
            capture(app, "palette-page-\(theme)")
            tapTab(.overview, in: app)
            capture(app, "palette-overview-\(theme)")
            tapTab(.settings, in: app)
        }
        XCTAssertEqual(paintedPages.count, 4, "Every palette must visibly recolor the page.")
        XCTAssertFalse(themeRow("classic", in: app).exists)
        XCTAssertFalse(themeRow("vivid", in: app).exists)
        XCTAssertFalse(app.buttons["appearance.surface.solid"].exists)
        capture(app, "habit-theme-all-palettes-available")
    }
}

/// Photographs every paid palette (#113) for the PR record: Today,
/// Overview and the medium widget, in whichever appearance the
/// simulator is in — `simctl ui <udid> appearance dark` between two
/// runs gives both. Asserts only that each screen was reached, so
/// `make e2e` skips it, as it does `ScreenshotTests`.
final class HabitPaletteCaptureTests: TendelmUITestCase {

    private let paidThemes = ["muted", "autumn", "monochromeSage"]

    @MainActor
    func testCaptureEveryPaidPalette() {
        for theme in paidThemes {
            let app = launchApp(
                seedProduction: true, seedForScreenshots: true,
                supporter: true, habitTheme: theme
            )
            waitForTodayRows(in: app)
            capture(app, "palette-\(theme)-today")
            tapTab(.overview, in: app)
            Thread.sleep(forTimeInterval: 1.0)
            capture(app, "palette-\(theme)-overview")
            app.terminate()

            let gallery = launchApp(
                seedProduction: true, seedForScreenshots: true, widgetGallery: true,
                supporter: true, habitTheme: theme
            )
            let medium = gallery.otherElements[AccessibilityID.Screenshot.widgetMedium]
            XCTAssertTrue(medium.waitForExistence(timeout: 30), "No widget gallery for \(theme).")
            Thread.sleep(forTimeInterval: 1.0)
            let attachment = XCTAttachment(screenshot: medium.screenshot())
            attachment.name = "palette-\(theme)-widget"
            attachment.lifetime = .keepAlways
            add(attachment)
            gallery.terminate()
        }
    }
}
