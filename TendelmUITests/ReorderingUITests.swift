import XCTest

final class ReorderingUITests: TendelmUITestCase {
    @MainActor
    func testTrackerDragPersistsAndStillOpensDetail() {
        var app = launchApp(seedProduction: true, seedTimeSince: true)
        tapTab(.timeSince, in: app)
        let ids = gripIDs("reorder.tracker.", in: app)
        XCTAssertEqual(ids.count, 2)
        moveSecondAboveFirst(ids, in: app)
        capture(app, "time-since-reordered")
        XCTAssertEqual(gripIDs("reorder.tracker.", in: app), [ids[1], ids[0]])
        let addTracker = app.buttons["timeSince.new"]
        XCTAssertTrue(addTracker.waitForExistence(timeout: 5))
        XCTAssertTrue(addTracker.isHittable)
        addTracker.tap()
        XCTAssertTrue(app.textFields["timeSince.name"].waitForExistence(timeout: 5))
        capture(app, "new-tracker-after-reorder")
        app.buttons["Cancel"].tap()
        capture(app, "time-since-after-editor-cancel")
        app.terminate()
        app = launchApp(resetState: false)
        tapTab(.timeSince, in: app)
        XCTAssertEqual(gripIDs("reorder.tracker.", in: app), [ids[1], ids[0]])
        let trackerID = String(ids[1].dropFirst("reorder.tracker.".count))
        app.buttons["timeSince.detail.\(trackerID)"].tap()
        XCTAssertTrue(app.buttons["timeSince.detail.reset"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testHabitListDragPersists() { exerciseHabitDrag(cards: false) }

    @MainActor
    func testHabitCardDragPersists() { exerciseHabitDrag(cards: true) }

    @MainActor
    private func exerciseHabitDrag(cards: Bool) {
        var app = launchApp(seedProduction: true)
        waitForTodayRows(in: app)
        if cards {
            app.buttons["today.layout"].tap()
            app.buttons["Cards"].tap()
        }
        let ids = gripIDs("reorder.habit.", in: app)
        XCTAssertGreaterThanOrEqual(ids.count, 2)
        moveSecondAboveFirst(ids, in: app)
        capture(app, cards ? "habit-cards-reordered" : "habit-list-reordered")
        XCTAssertEqual(gripIDs("reorder.habit.", in: app).first, ids[1])
        app.terminate()
        app = launchApp(resetState: false)
        waitForTodayRows(in: app)
        XCTAssertEqual(gripIDs("reorder.habit.", in: app).first, ids[1])
    }

    @MainActor
    private func gripIDs(_ prefix: String, in app: XCUIApplication) -> [String] {
        let query = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH %@", prefix))
        XCTAssertTrue(query.firstMatch.waitForExistence(timeout: 10))
        var seen = Set<String>()
        return query.allElementsBoundByIndex.filter { $0.isHittable }
            .sorted { $0.frame.minY < $1.frame.minY }
            .map(\.identifier).filter { seen.insert($0).inserted }
    }

    @MainActor
    private func moveSecondAboveFirst(_ ids: [String], in app: XCUIApplication) {
        guard ids.count >= 2 else { XCTFail("Need two visible items"); return }
        let first = app.descendants(matching: .any)[ids[0]].firstMatch
        let second = app.descendants(matching: .any)[ids[1]].firstMatch
        capture(app, "before-handle-drag")
        second.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            .press(forDuration: 0.8, thenDragTo: first.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)))
        capture(app, "after-handle-drag")
        XCTAssertFalse(app.buttons["habit.delete"].exists)
        XCTAssertFalse(app.buttons["tracker.delete"].exists)
    }
}
