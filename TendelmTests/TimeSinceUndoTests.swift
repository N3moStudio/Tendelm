import Foundation
import Testing
import TendelmCore

@Suite("Recent time-since undo")
struct TimeSinceUndoTests {
    private let start = Date(timeIntervalSince1970: 1_700_000_000)

    @Test("Undo expires at six seconds and never changes history afterward")
    func expires() throws {
        var tracker = TimeSinceTracker(name: "Coffee", startedAt: start)
        let change = try tracker.reset(at: start.addingTimeInterval(10))
        let now = ContinuousClock.now
        let action = TimeSinceUndoAction(trackerID: tracker.id, change: .added(change), now: now)
        let saved = tracker
        #expect(try !action.undo(in: &tracker, now: now.advanced(by: .seconds(6))))
        #expect(tracker == saved)
        #expect(try !action.undo(in: &tracker, now: now.advanced(by: .seconds(60))))
        #expect(tracker == saved)
    }

    @Test("The recent change removes one exact reset without walking backward")
    func latestChangeOnly() throws {
        var tracker = TimeSinceTracker(name: "Coffee", startedAt: start)
        try tracker.reset(at: start.addingTimeInterval(10))
        let latest = try tracker.reset(at: start.addingTimeInterval(20))
        let now = ContinuousClock.now
        let action = TimeSinceUndoAction(trackerID: tracker.id, change: .added(latest), now: now)
        #expect(try action.undo(in: &tracker, now: now))
        #expect(tracker.orderedResets.map(\.date) == [start.addingTimeInterval(10)])
        #expect(try !action.undo(in: &tracker, now: now))
        #expect(tracker.resets.count == 1)
    }

    @Test("A backfilled reset can be undone without removing newer history")
    func backfilledReset() throws {
        var tracker = TimeSinceTracker(name: "Coffee", startedAt: start)
        try tracker.reset(at: start.addingTimeInterval(30))
        let saved = tracker
        let added = try tracker.recordPreviousReset(at: start.addingTimeInterval(-60), now: start)
        let action = TimeSinceUndoAction(trackerID: tracker.id, change: .added(added))
        #expect(try action.undo(in: &tracker))
        #expect(tracker == saved)
    }

    @Test("Deleting and restoring any selected event preserves other history", arguments: [0, 1, 2])
    func deleteAndRestore(index: Int) throws {
        var tracker = TimeSinceTracker(name: "Coffee", startedAt: start)
        for seconds in [10.0, 20.0, 30.0] { try tracker.reset(at: start.addingTimeInterval(seconds)) }
        let events = tracker.orderedResets
        let deleted = tracker.deleteReset(id: events[index].id)
        let removed = try #require(deleted)
        #expect(tracker.startedAt == start)
        #expect(tracker.resets.count == 2)
        #expect(!tracker.resets.contains(removed))
        #expect(tracker.currentStart == (index == 2 ? events[1].date : events[2].date))
        let action = TimeSinceUndoAction(trackerID: tracker.id, change: .deleted(removed))
        tracker.name = "Less coffee"
        #expect(try action.undo(in: &tracker))
        #expect(tracker.name == "Less coffee")
        #expect(tracker.orderedResets == events)
        #expect(try !action.undo(in: &tracker))
        try tracker.validate()
    }

    @Test("Undo cannot touch a different tracker or overwrite an intervening edit")
    func safeguards() throws {
        var tracker = TimeSinceTracker(name: "Coffee", startedAt: start)
        let added = try tracker.reset(at: start.addingTimeInterval(10))
        let deleted = tracker.deleteReset(id: added.reset.id)
        let removed = try #require(deleted)
        let action = TimeSinceUndoAction(trackerID: tracker.id, change: .deleted(removed))
        var other = TimeSinceTracker(name: "Scrolling", startedAt: start)
        let otherBefore = other
        #expect(try !action.undo(in: &other))
        #expect(other == otherBefore)
        tracker.startedAt = start.addingTimeInterval(20)
        let before = tracker
        #expect(throws: TimeSinceError.invalidTracker) { try action.undo(in: &tracker) }
        #expect(tracker == before)
    }

    @Test("Extended accessibility timing is still bounded")
    func extendedLifetime() throws {
        var tracker = TimeSinceTracker(name: "Coffee", startedAt: start)
        let added = try tracker.reset(at: start)
        let now = ContinuousClock.now
        let action = TimeSinceUndoAction(trackerID: tracker.id, change: .added(added), now: now, lifetime: .seconds(20))
        #expect(try !action.undo(in: &tracker, now: now.advanced(by: .seconds(20))))
        #expect(try action.undo(in: &tracker, now: now.advanced(by: .seconds(19))))
    }
}
