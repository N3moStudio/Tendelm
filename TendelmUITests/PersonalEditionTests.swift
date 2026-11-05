import XCTest

final class PersonalEditionTests: TendelmUITestCase {
    @MainActor
    func testPreviousResetCancelSaveUndoAndRelaunch() {
        var app = launchApp(seedProduction: true, seedTimeSince: true)
        tapTab(.timeSince, in: app)
        let detail = buttons("timeSince.detail.", in: app).firstMatch
        XCTAssertTrue(detail.waitForExistence(timeout: 5))
        let detailID = detail.identifier
        detail.tap()
        app.buttons["timeSince.detail.reset"].tap()
        let before = app.staticTexts.matching(NSPredicate(format: "label == 'Reset logged'")).count
        let previous = app.buttons["timeSince.detail.previous"]
        XCTAssertTrue(previous.exists)
        previous.tap()
        XCTAssertTrue(app.datePickers["timeSince.previous.date"].waitForExistence(timeout: 5))
        app.buttons["Cancel"].tap()
        XCTAssertEqual(app.staticTexts.matching(NSPredicate(format: "label == 'Reset logged'")).count, before)
        previous.tap()
        photograph(app, "09-previous-reset-picker")
        app.buttons["timeSince.previous.save"].tap()
        XCTAssertTrue(previous.waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts.matching(NSPredicate(format: "label == 'Reset logged'")).count, before + 1)
        XCTAssertTrue(app.buttons["timeSince.detail.undo"].label.contains("Undo added reset"))
        app.buttons["timeSince.detail.undo"].tap()
        XCTAssertEqual(app.staticTexts.matching(NSPredicate(format: "label == 'Reset logged'")).count, before)
        previous.tap()
        app.buttons["timeSince.previous.save"].tap()
        XCTAssertTrue(previous.waitForExistence(timeout: 5))
        app.terminate()
        app = launchApp(resetState: false)
        tapTab(.timeSince, in: app)
        app.buttons[detailID].tap()
        XCTAssertTrue(app.buttons["timeSince.detail.previous"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts.matching(NSPredicate(format: "label == 'Reset logged'")).count, before + 1)
    }

    @MainActor
    func testExternalImportEntryAndHelp() {
        let app = launchApp()
        tapTab(.settings, in: app)
        let entry = app.buttons["externalImport.open"]
        for _ in 0..<5 {
            if entry.isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(entry.isHittable)
        entry.tap()
        XCTAssertTrue(app.buttons["externalImport.choose"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["externalImport.confirm"].exists)
        app.buttons["Streaks"].tap()
        XCTAssertTrue(app.descendants(matching: .any).matching(NSPredicate(format: "label == 'Streaks export help'")).firstMatch.exists)
        photograph(app, "10-import-history")
    }

    @MainActor
    func testChooseFutureDateThenEditAndRelaunch() throws {
        var app = launchApp()
        tapTab(.timeSince, in: app)
        app.buttons["timeSince.new"].tap()
        let field = nameField(in: app)
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.typeText("Starting next month")
        app.buttons["Start date & color"].tap()
        let date = app.datePickers["timeSince.start"]
        XCTAssertTrue(date.waitForExistence(timeout: 5), app.debugDescription)
        date.buttons.firstMatch.tap()
        let next = app.buttons["Next Month"].firstMatch
        XCTAssertTrue(next.waitForExistence(timeout: 5), app.debugDescription)
        next.tap()
        let fifteenth = app.buttons.matching(NSPredicate(format: "label CONTAINS '15'")).firstMatch
        XCTAssertTrue(fifteenth.exists, app.debugDescription)
        fifteenth.tap()
        let dismissRegion = app.otherElements["PopoverDismissRegion"].firstMatch
        XCTAssertTrue(dismissRegion.waitForExistence(timeout: 5), app.debugDescription)
        dismissRegion.tap()
        XCTAssertTrue(next.waitForNonExistence(timeout: 5))
        photograph(app, "06-future-start-editor")
        app.buttons["timeSince.save"].tap()
        XCTAssertTrue(app.staticTexts["Starting next month"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["timeSince.scheduled"].exists)
        XCTAssertFalse(buttons("timeSince.reset.", in: app).firstMatch.isEnabled)
        photograph(app, "07-scheduled-tracker")
        buttons("timeSince.detail.", in: app).firstMatch.tap()
        XCTAssertFalse(app.buttons["timeSince.detail.reset"].isEnabled)
        photograph(app, "08-scheduled-detail")
        app.buttons["timeSince.options"].tap()
        app.buttons["timeSince.edit"].tap()
        app.buttons["timeSince.save"].tap()
        XCTAssertTrue(app.staticTexts["timeSince.scheduled"].exists)
        app.terminate()
        app = launchApp(resetState: false)
        tapTab(.timeSince, in: app)
        XCTAssertTrue(app.staticTexts["Starting next month"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["timeSince.scheduled"].exists)
        XCTAssertFalse(buttons("timeSince.reset.", in: app).firstMatch.isEnabled)
    }

    @MainActor
    func testScheduledTrackerStartsAutomatically() {
        let app = launchApp(seedProduction: true, scheduledStartOffset: 20)
        tapTab(.timeSince, in: app)
        let detail = buttons("timeSince.detail.", in: app).firstMatch
        XCTAssertTrue(detail.waitForExistence(timeout: 5))
        detail.tap()
        let reset = app.buttons["timeSince.detail.reset"]
        XCTAssertTrue(reset.waitForExistence(timeout: 5))
        XCTAssertFalse(reset.isEnabled)
        XCTAssertTrue(app.staticTexts["timeSince.scheduled"].exists)
        let starts = expectation(for: NSPredicate(format: "isEnabled == true"), evaluatedWith: reset)
        wait(for: [starts], timeout: 30)
        XCTAssertFalse(app.staticTexts["timeSince.scheduled"].exists)
        reset.tap()
        XCTAssertTrue(app.buttons["timeSince.detail.undo"].waitForExistence(timeout: 5))
    }

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
        // Tapping an existing field can place its cursor at either end.
        // Check the actual edited value rather than assuming a cursor position.
        field.typeText(" less")
        let editedName = try XCTUnwrap(field.value as? String).trimmingCharacters(in: .whitespacesAndNewlines)
        XCTAssertNotEqual(editedName, "Late-night scrolling")
        app.buttons["timeSince.save"].tap()
        XCTAssertTrue(app.staticTexts[editedName].waitForExistence(timeout: 5))
        app.terminate()
        app = launchApp(resetState: false)
        tapTab(.timeSince, in: app)
        XCTAssertTrue(app.staticTexts[editedName].waitForExistence(timeout: 5))
    }

    @MainActor
    func testCardsPreserveHabitNavigationAndCreation() throws {
        let app = launchApp(seedProduction: true, seedForScreenshots: true)
        waitForTodayRows(in: app)
        chooseCards(in: app)
        XCTAssertTrue(todayRows(in: app).firstMatch.exists)
        // A combined row also exposes its quick-log control. Test the actual
        // name and grid touch regions instead of XCTest's chosen activation point.
        app.staticTexts["Morning meditation"].firstMatch.tap()
        XCTAssertTrue(app.buttons[AccessibilityID.HabitDetail.scoreCard].firstMatch.waitForExistence(timeout: 10))
        leaveHabitDetail(in: app)
        todayRows(in: app).firstMatch.coordinate(withNormalizedOffset: CGVector(dx: 0.45, dy: 0.75)).tap()
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
        XCTAssertTrue(option.waitForNonExistence(timeout: 5))
        // Let the system menu's dismissal finish before a screenshot or tap.
        RunLoop.current.run(until: Date().addingTimeInterval(0.5))
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
        // Navigation/menu transitions can outlive XCTest's idle signal.
        RunLoop.current.run(until: Date().addingTimeInterval(0.6))
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
