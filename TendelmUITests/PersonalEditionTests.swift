import XCTest

final class PersonalEditionTests: TendelmUITestCase {
    @MainActor
    func testCreateResetUndoEditAndRelaunch() throws {
        var app = launchApp()
        tapTab(.timeSince, in: app)
        XCTAssertTrue(app.buttons["Start a tracker"].waitForExistence(timeout: 10))
        addTracker("Late-night scrolling", in: app)
        addTracker("Nail biting", in: app)
        let resets = buttons("timeSince.reset.", in: app)
        XCTAssertEqual(resets.count, 2)
        let firstID = String(resets.element(boundBy: 0).identifier.dropFirst("timeSince.reset.".count))
        let secondID = String(resets.element(boundBy: 1).identifier.dropFirst("timeSince.reset.".count))
        resets.element(boundBy: 0).tap()
        XCTAssertTrue(app.buttons["timeSince.undo.\(firstID)"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["timeSince.undo.\(secondID)"].exists)
        app.buttons["timeSince.undo.\(firstID)"].tap()
        XCTAssertFalse(app.buttons["timeSince.undo.\(firstID)"].exists)
        app.buttons["timeSince.reset.\(firstID)"].tap()
        app.terminate()
        app = launchApp(resetState: false)
        tapTab(.timeSince, in: app)
        XCTAssertEqual(buttons("timeSince.reset.", in: app).count, 2)
        app.buttons["timeSince.detail.\(firstID)"].tap()
        XCTAssertTrue(app.buttons["timeSince.detail.undo"].waitForExistence(timeout: 5))
        app.buttons["timeSince.detail.undo"].tap()
        XCTAssertFalse(app.buttons["timeSince.detail.undo"].exists)
        app.buttons["timeSince.options"].tap()
        app.buttons["timeSince.edit"].tap()
        let field = nameField(in: app)
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        // Append rather than relying on a localized Select All menu.
        field.typeText(" less")
        app.buttons["timeSince.save"].tap()
        XCTAssertTrue(app.staticTexts["Late-night scrolling less"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testCardsPreserveHabitNavigationAndCreation() throws {
        let app = launchApp(seedProduction: true, seedForScreenshots: true)
        waitForTodayRows(in: app)
        chooseCards(in: app)
        XCTAssertTrue(todayRows(in: app).firstMatch.exists)
        todayRows(in: app).firstMatch.tap()
        XCTAssertTrue(app.buttons[AccessibilityID.HabitDetail.scoreCard].firstMatch.waitForExistence(timeout: 10))
        leaveHabitDetail(in: app)
        app.buttons[AccessibilityID.Today.newHabitButton].firstMatch.tap()
        XCTAssertTrue(app.textFields[AccessibilityID.NewHabit.nameField].waitForExistence(timeout: 5))
        app.buttons[AccessibilityID.NewHabit.cancelButton].firstMatch.tap()
    }

    @MainActor
    func testCapturePersonalScreens() throws {
        let app = launchApp(seedProduction: true, seedForScreenshots: true, seedTimeSince: true)
        waitForTodayRows(in: app)
        chooseCards(in: app)
        photograph(app, "01-habit-cards")
        tapTab(.timeSince, in: app)
        XCTAssertEqual(buttons("timeSince.reset.", in: app).count, 2)
        photograph(app, "02-time-since")
        buttons("timeSince.detail.", in: app).firstMatch.tap()
        XCTAssertTrue(app.buttons["timeSince.detail.reset"].waitForExistence(timeout: 5))
        photograph(app, "03-tracker-detail")
    }

    @MainActor
    func testCaptureLargeText() throws {
        let app = launchApp(seedProduction: true, seedForScreenshots: true, seedTimeSince: true,
            contentSize: "UICTContentSizeCategoryAccessibilityXXXL")
        tapTab(.timeSince, in: app)
        XCTAssertTrue(buttons("timeSince.reset.", in: app).firstMatch.waitForExistence(timeout: 5))
        photograph(app, "04-large-text")
        buttons("timeSince.detail.", in: app).firstMatch.tap()
        photograph(app, "05-large-text-detail")
    }

    @MainActor
    private func chooseCards(in app: XCUIApplication) {
        app.buttons["today.layout"].firstMatch.tap()
        let option = app.buttons["Cards"].firstMatch
        XCTAssertTrue(option.waitForExistence(timeout: 5))
        option.tap()
    }

    @MainActor
    private func addTracker(_ name: String, in app: XCUIApplication) {
        app.buttons["timeSince.new"].tap()
        let field = nameField(in: app)
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText(name)
        app.buttons["timeSince.save"].tap()
        XCTAssertTrue(app.staticTexts[name].waitForExistence(timeout: 5))
    }

    @MainActor
    private func nameField(in app: XCUIApplication) -> XCUIElement {
        let field = app.textFields["timeSince.name"]
        if field.exists { return field }
        return app.textViews["timeSince.name"]
    }

    @MainActor
    private func buttons(_ prefix: String, in app: XCUIApplication) -> XCUIElementQuery {
        app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", prefix))
    }

    @MainActor
    private func photograph(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
