import XCTest

final class PasteImportTests: TendelmUITestCase {
    private let historyJSON = #"[{"habit":"Pasted reading","date":"2025-01-01","status":"completed","habit_id":"reading"}]"#
    private let backupJSON = #"{"formatVersion":2,"exportedAt":"2025-01-02T00:00:00Z","appVersion":"test","habits":[],"timeSinceTrackers":[{"id":"DAF62241-5034-4149-8B24-0951226647DA","name":"Pasted tracker","startedAt":"2025-01-01T00:00:00Z","color":"green","resets":[]}]}"#

    @MainActor
    func testBackupPasteCancelImportAndRelaunch() {
        var app = launchApp(clipboardText: backupJSON)
        tapTab(.settings, in: app)
        reveal(app.buttons["backup.paste"], in: app)
        app.buttons["backup.paste"].tap()
        let confirm = app.buttons["backup.review.confirm"]
        XCTAssertTrue(confirm.waitForExistence(timeout: 5), app.debugDescription)
        capture(app, "14-pasted-backup-review")
        app.buttons["backup.review.cancel"].tap()
        tapTab(.timeSince, in: app)
        XCTAssertTrue(app.buttons["Start a tracker"].waitForExistence(timeout: 5))
        tapTab(.settings, in: app)
        reveal(app.buttons["backup.paste"], in: app)
        app.buttons["backup.paste"].tap()
        XCTAssertTrue(confirm.waitForExistence(timeout: 5))
        confirm.tap()
        XCTAssertTrue(app.alerts["Import complete"].waitForExistence(timeout: 5))
        app.alerts.buttons["OK"].tap()
        app.terminate()
        app = launchApp(resetState: false)
        tapTab(.timeSince, in: app)
        XCTAssertTrue(app.staticTexts["Pasted tracker"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testHistoryPastePreviewCancelAndRepeatImport() {
        var app = launchApp(clipboardText: historyJSON)
        openHistory(in: app)
        app.buttons["externalImport.paste"].tap()
        let confirm = app.buttons["externalImport.confirm"]
        waitForHistoryPreview(in: app)
        reveal(confirm, in: app)
        capture(app, "15-pasted-history-preview")
        reveal(app.buttons["externalImport.cancel"], in: app)
        app.buttons["externalImport.cancel"].tap()
        XCTAssertTrue(confirm.waitForNonExistence(timeout: 3))
        app.terminate()
        app = launchApp(resetState: false, clipboardText: historyJSON)
        openHistory(in: app)
        app.buttons["externalImport.paste"].tap()
        waitForHistoryPreview(in: app)
        reveal(app.buttons["externalImport.confirm"], in: app)
        app.buttons["externalImport.confirm"].tap()
        XCTAssertTrue(app.alerts["History imported"].waitForExistence(timeout: 5))
        app.alerts.buttons["OK"].tap()
        reveal(app.buttons["externalImport.paste"], in: app, scrollDown: true)
        app.buttons["externalImport.paste"].tap()
        waitForHistoryPreview(in: app)
        reveal(app.staticTexts["This history is already in Tendelm."], in: app)
        XCTAssertFalse(app.buttons["externalImport.confirm"].exists)
    }

    @MainActor
    func testCSVTextAndInvalidLink() {
        var app = launchApp(clipboardText: "https://example.com/export.csv")
        openHistory(in: app)
        app.buttons["externalImport.paste"].tap()
        XCTAssertTrue(app.alerts["Couldn't import"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["externalImport.confirm"].exists)
        app.terminate()
        app = launchApp(resetState: false, clipboardText: "habit,date,status\nPasted CSV,2025-01-01,completed")
        openHistory(in: app)
        app.buttons["externalImport.paste"].tap()
        waitForHistoryPreview(in: app)
        reveal(app.buttons["externalImport.confirm"], in: app)
    }

    @MainActor
    func testJSONHelperReturnsToPasteWithoutImporting() {
        let app = launchApp(clipboardText: backupJSON)
        tapTab(.settings, in: app)
        let helper = app.buttons["backup.helper"]
        reveal(helper, in: app)
        capture(app, "16-backup-paste-and-helper")
        helper.tap()
        let done = app.buttons["Done"].firstMatch
        XCTAssertTrue(done.waitForExistence(timeout: 15), app.debugDescription)
        done.tap()
        XCTAssertTrue(helper.waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["backup.review.confirm"].exists)
        reveal(app.buttons["backup.paste"], in: app, scrollDown: true)
        app.buttons["backup.paste"].tap()
        XCTAssertTrue(app.buttons["backup.review.confirm"].waitForExistence(timeout: 5))
        app.buttons["backup.review.cancel"].tap()
    }

    @MainActor
    private func openHistory(in app: XCUIApplication) {
        tapTab(.settings, in: app)
        let entry = app.buttons["externalImport.open"]
        reveal(entry, in: app)
        entry.tap()
        XCTAssertTrue(app.buttons["externalImport.paste"].waitForExistence(timeout: 5))
    }

    @MainActor
    private func waitForHistoryPreview(in app: XCUIApplication) {
        let preview = app.descendants(matching: .any).matching(identifier: "externalImport.newDays").firstMatch
        XCTAssertTrue(preview.waitForExistence(timeout: 5), app.debugDescription)
    }

    @MainActor
    private func reveal(_ element: XCUIElement, in app: XCUIApplication, scrollDown: Bool = false) {
        for _ in 0..<7 {
            if element.isHittable { break }
            if scrollDown { app.swipeDown() } else { app.swipeUp() }
        }
        XCTAssertTrue(element.isHittable, app.debugDescription)
    }

    @MainActor
    private func capture(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
