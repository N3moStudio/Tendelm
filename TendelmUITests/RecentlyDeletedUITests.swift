import XCTest

final class RecentlyDeletedUITests: TendelmUITestCase {
    override func setUp() {
        super.setUp()
        // iOS context menus can incur two 60-second XCTest animation-idle waits.
        executionTimeAllowance = 360
    }
    @MainActor
    func testTodayDeleteAndRestoreSurviveRelaunch() {
        var app = launchApp(seedProduction: true)
        waitForTodayRows(in: app)
        let row = todayRows(in: app).firstMatch
        let id = habitID(of: row, prefix: "today.row.")
        row.press(forDuration: 1)
        assertDeleteOnly(in: app, identifier: "habit.delete")
        capture(app, "17-habit-delete-menu")
        app.buttons["habit.delete"].tap()
        XCTAssertTrue(todayRow(id, in: app).waitForNonExistence(timeout: 5))
        tapTab(.settings, in: app)
        capture(app, "22-grouped-settings")
        openSettingsPage("settings.recentlyDeleted", in: app)
        let restore = prefixedButton("trash.restore.", in: app)
        XCTAssertTrue(restore.waitForExistence(timeout: 5))
        capture(app, "18-recently-deleted")
        app.terminate()
        app = launchApp(resetState: false)
        openSettingsPage("settings.recentlyDeleted", in: app)
        prefixedButton("trash.restore.", in: app).tap()
        XCTAssertTrue(elements(withIdentifierPrefix: "trash.empty", in: app).firstMatch.waitForExistence(timeout: 5))
        tapTab(.today, in: app)
        XCTAssertTrue(todayRow(id, in: app).waitForExistence(timeout: 5))
    }

    @MainActor
    func testCardsAndOverviewDeleteSelection() {
        let app = launchApp(seedProduction: true)
        waitForTodayRows(in: app)
        app.buttons["today.layout"].tap()
        app.buttons["Cards"].tap()
        let first = todayRows(in: app).firstMatch
        let firstID = habitID(of: first, prefix: "today.row.")
        first.press(forDuration: 1)
        assertDeleteOnly(in: app, identifier: "habit.delete")
        app.buttons["habit.delete"].tap()
        XCTAssertTrue(todayRow(firstID, in: app).waitForNonExistence(timeout: 5))
        tapTab(.overview, in: app)
        let labels = elements(withIdentifierPrefix: "overview.label.", in: app)
        let label = labels.firstMatch
        XCTAssertTrue(label.waitForExistence(timeout: 5), app.debugDescription)
        let labelID = label.identifier
        label.press(forDuration: 1)
        assertDeleteOnly(in: app, identifier: "habit.delete")
        app.buttons["habit.delete"].tap()
        XCTAssertTrue(app.descendants(matching: .any)[labelID].firstMatch.waitForNonExistence(timeout: 5))
        openSettingsPage("settings.recentlyDeleted", in: app)
        app.buttons["trash.select"].tap()
        app.buttons["trash.selectAll"].tap()
        XCTAssertEqual(app.buttons["trash.selectAll"].label, "Deselect All")
        app.buttons["trash.selectAll"].tap()
        XCTAssertEqual(app.buttons["trash.deleteSelected"].label, "Delete All")
        prefixedButton("trash.select.", in: app).tap()
        XCTAssertEqual(app.buttons["trash.deleteSelected"].label, "Delete (1)")
        capture(app, "19-recently-deleted-selection")
        app.buttons["trash.deleteSelected"].tap()
        cancelConfirmation("trash.confirmDelete", in: app)
        XCTAssertTrue(app.buttons["trash.restoreSelected"].exists)
        app.buttons["trash.deleteSelected"].tap()
        app.buttons["trash.confirmDelete"].firstMatch.tap()
        XCTAssertEqual(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'trash.select.'")).count, 1)
        app.buttons["trash.deleteSelected"].tap()
        app.buttons["trash.confirmDelete"].firstMatch.tap()
        XCTAssertTrue(elements(withIdentifierPrefix: "trash.empty", in: app).firstMatch.waitForExistence(timeout: 5))
        tapTab(.today, in: app)
        XCTAssertTrue(todayRows(in: app).firstMatch.exists)
    }

    @MainActor
    func testTrackerRestoresHistory() {
        let app = launchApp(seedProduction: true, seedTimeSince: true)
        tapTab(.timeSince, in: app)
        let detail = prefixedButton("timeSince.detail.", in: app)
        XCTAssertTrue(detail.waitForExistence(timeout: 5))
        let detailID = detail.identifier
        detail.press(forDuration: 1)
        assertDeleteOnly(in: app, identifier: "tracker.delete")
        app.buttons["tracker.delete"].tap()
        XCTAssertTrue(app.buttons[detailID].waitForNonExistence(timeout: 5))
        openSettingsPage("settings.recentlyDeleted", in: app)
        prefixedButton("trash.restore.", in: app).tap()
        tapTab(.timeSince, in: app)
        app.buttons[detailID].tap()
        XCTAssertTrue(app.buttons["timeSince.detail.previous"].waitForExistence(timeout: 5))
        XCTAssertTrue(elements(withIdentifierPrefix: "timeSince.history.", in: app).firstMatch.exists)
    }

    @MainActor
    func testFullEraseCancelThenConfirmAndRelaunch() {
        var app = launchApp(seedProduction: true, seedTimeSince: true)
        waitForTodayRows(in: app)
        todayRows(in: app).firstMatch.press(forDuration: 1)
        app.buttons["habit.delete"].tap()
        openSettingsPage("settings.privacy", in: app)
        scrollTo(app.buttons["settings.erase"], in: app)
        app.buttons["settings.erase"].tap()
        cancelConfirmation("settings.eraseConfirm", in: app)
        tapTab(.today, in: app)
        XCTAssertTrue(todayRows(in: app).firstMatch.exists)
        tapTab(.settings, in: app)
        app.buttons["settings.erase"].tap()
        app.buttons["settings.eraseConfirm"].firstMatch.tap()
        XCTAssertTrue(app.buttons["settings.eraseConfirm"].firstMatch.waitForNonExistence(timeout: 5))
        tapTab(.today, in: app)
        XCTAssertEqual(todayRows(in: app).count, 0)
        tapTab(.timeSince, in: app)
        XCTAssertTrue(app.buttons["Start a tracker"].waitForExistence(timeout: 5))
        openSettingsPage("settings.recentlyDeleted", in: app)
        XCTAssertTrue(elements(withIdentifierPrefix: "trash.empty", in: app).firstMatch.waitForExistence(timeout: 5))
        app.terminate()
        app = launchApp(resetState: false)
        XCTAssertEqual(todayRows(in: app).count, 0)
        tapTab(.timeSince, in: app)
        XCTAssertTrue(app.buttons["Start a tracker"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testGroupedSettingsAtLargeText() {
        let app = launchApp(seedProduction: true, contentSize: "UICTContentSizeCategoryAccessibilityXXXL")
        tapTab(.settings, in: app)
        XCTAssertLessThan(app.buttons[AccessibilityID.Settings.appearanceRow].frame.height, app.frame.height * 0.5)
        capture(app, "20-grouped-settings-large-text")
        scrollTo(app.buttons["settings.importExport"], in: app)
        app.buttons["settings.importExport"].tap()
        XCTAssertTrue(app.buttons["backup.paste"].waitForExistence(timeout: 5))
        XCTAssertLessThan(app.staticTexts["Paste backup text"].frame.height, app.frame.height * 0.3)
        capture(app, "21-import-settings-large-text")
        scrollTo(app.links["json.site"].firstMatch, in: app)
    }

    @MainActor
    private func cancelConfirmation(_ confirmID: String, in app: XCUIApplication) {
        let confirm = app.buttons[confirmID].firstMatch
        XCTAssertTrue(confirm.waitForExistence(timeout: 5))
        let cancel = app.buttons["Cancel"].firstMatch
        if cancel.exists {
            cancel.tap()
        } else {
            // Native popover confirmations omit Cancel; tapping outside dismisses.
            // The navigation title is outside both of these bottom/middle anchors.
            app.navigationBars.firstMatch.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        }
        XCTAssertTrue(confirm.waitForNonExistence(timeout: 5))
    }

    @MainActor
    private func todayRow(_ id: UUID, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: "today.row.\(id.uuidString)").firstMatch
    }

    @MainActor
    private func habitID(of element: XCUIElement, prefix: String) -> UUID {
        let id = UUID(uuidString: String(element.identifier.dropFirst(prefix.count)))
        XCTAssertNotNil(id)
        return id ?? UUID()
    }

    @MainActor
    private func assertDeleteOnly(in app: XCUIApplication, identifier: String) {
        XCTAssertTrue(app.buttons[identifier].waitForExistence(timeout: 5), app.debugDescription)
        XCTAssertFalse(app.buttons["Edit"].isHittable)
        XCTAssertFalse(app.buttons["Archive"].isHittable)
    }

    @MainActor
    private func prefixedButton(_ prefix: String, in app: XCUIApplication) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", prefix)).firstMatch
    }
}
