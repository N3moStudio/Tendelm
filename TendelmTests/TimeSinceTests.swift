import Foundation
import Testing
import SwiftData
import TendelmCore

@Suite("Time since")
struct TimeSinceTests {
    let start = Date(timeIntervalSince1970: 1_700_000_000)

    @Test("Elapsed duration is exact through days, hours, minutes and seconds")
    func components() {
        // 2 days + 3 hours + 4 minutes + 5 seconds.
        let value = ElapsedDuration(from: start, to: start.addingTimeInterval(183_845))
        #expect(value.days == 2)
        #expect(value.hours == 3)
        #expect(value.minutes == 4)
        #expect(value.seconds == 5)
    }

    @Test("A future start never renders negative time")
    func futureStart() {
        #expect(ElapsedDuration(from: start, to: start.addingTimeInterval(-1)).totalSeconds == 0)
    }

    @Test("A scheduled tracker counts down and becomes elapsed at the exact start")
    func scheduledBoundary() {
        let before = TimeSinceStatus(start: start, now: start.addingTimeInterval(-90_061))
        #expect(before.isScheduled)
        #expect(before.duration.days == 1)
        #expect(before.duration.hours == 1)
        #expect(before.duration.minutes == 1)
        #expect(before.duration.seconds == 1)
        let edge = TimeSinceStatus(start: start, now: start)
        #expect(!edge.isScheduled)
        #expect(edge.duration.totalSeconds == 0)
        let after = TimeSinceStatus(start: start, now: start.addingTimeInterval(61))
        #expect(!after.isScheduled)
        #expect(after.duration.totalSeconds == 61)
    }

    @Test("A future tracker validates, rejects an early reset, then can reset at its start")
    func futureTracker() throws {
        let future = Date.now.addingTimeInterval(86_400)
        var tracker = TimeSinceTracker(name: "Later", startedAt: future)
        try tracker.validate()
        #expect(throws: TimeSinceError.clockMovedBackwards) { try tracker.reset(at: future.addingTimeInterval(-1)) }
        #expect(tracker.resets.isEmpty)
        try tracker.reset(at: future)
        #expect(tracker.resets.count == 1)
        try tracker.validate()
    }

    @Test("Reset changes only the selected tracker and undo restores its previous run")
    func resetAndUndo() throws {
        var first = TimeSinceTracker(name: "Late-night scrolling", startedAt: start)
        let other = TimeSinceTracker(name: "Nail biting", startedAt: start)
        let reset = start.addingTimeInterval(3600)
        try first.reset(at: reset)
        #expect(first.currentStart == reset)
        #expect(first.resets.count == 1)
        #expect(other.currentStart == start)
        first.undoLastReset()
        #expect(first.currentStart == start)
        #expect(first.resets.isEmpty)
    }

    @Test("Undo removes the latest reset even after unordered decoding")
    func unorderedHistory() {
        var value = TimeSinceTracker(name: "Test", startedAt: start, resets: [
            TimeSinceReset(date: start.addingTimeInterval(60)),
            TimeSinceReset(date: start.addingTimeInterval(30))
        ])
        value.undoLastReset()
        #expect(value.currentStart == start.addingTimeInterval(30))
    }

    @Test("A clock moving backwards does not erase elapsed time")
    func backwardsClock() {
        var value = TimeSinceTracker(name: "Test", startedAt: start)
        #expect(throws: TimeSinceError.self) { try value.reset(at: start.addingTimeInterval(-1)) }
        #expect(value.resets.isEmpty)
    }

    @Test("Durations use real elapsed time rather than calendar midnight")
    func travelAndDST() {
        let elapsed = ElapsedDuration(from: start, to: start.addingTimeInterval(25 * 3600))
        #expect(elapsed.days == 1)
        #expect(elapsed.hours == 1)
    }

    @Test("Backfilling history keeps the latest reset and undo targets the added event")
    func previousResetBetweenEvents() throws {
        var tracker = TimeSinceTracker(name: "Scrolling", startedAt: start)
        try tracker.reset(at: start.addingTimeInterval(10))
        try tracker.reset(at: start.addingTimeInterval(30))
        let original = tracker
        let change = try tracker.recordPreviousReset(at: start.addingTimeInterval(20), now: start.addingTimeInterval(40))
        #expect(tracker.currentStart == original.currentStart)
        #expect(tracker.orderedResets.map(\.date) == [10.0, 20.0, 30.0].map { start.addingTimeInterval($0) })
        tracker.undoPreviousReset(change)
        #expect(tracker == original)
    }

    @Test("A reset before the first start moves the baseline and can be undone exactly")
    func previousResetBeforeStart() throws {
        var tracker = TimeSinceTracker(name: "Coffee", startedAt: start)
        let original = tracker
        let earlier = start.addingTimeInterval(-86_400)
        let change = try tracker.recordPreviousReset(at: earlier, now: start)
        #expect(tracker.startedAt == earlier)
        #expect(tracker.currentStart == earlier)
        try tracker.validate()
        tracker.undoPreviousReset(change)
        #expect(tracker == original)
    }

    @Test("An added previous reset can become the latest real occurrence")
    func previousResetAfterLatest() throws {
        var tracker = TimeSinceTracker(name: "Coffee", startedAt: start)
        try tracker.reset(at: start.addingTimeInterval(10))
        try tracker.recordPreviousReset(at: start.addingTimeInterval(20), now: start.addingTimeInterval(30))
        #expect(tracker.currentStart == start.addingTimeInterval(20))
    }

    @Test("Future, nonfinite and duplicate previous resets leave history unchanged")
    func rejectsInvalidPreviousResets() throws {
        var tracker = TimeSinceTracker(name: "Coffee", startedAt: start)
        try tracker.reset(at: start)
        let original = tracker
        #expect(throws: TimeSinceError.resetMustBeInPast) {
            try tracker.recordPreviousReset(at: start.addingTimeInterval(1), now: start)
        }
        #expect(throws: TimeSinceError.resetMustBeInPast) {
            try tracker.recordPreviousReset(at: Date(timeIntervalSince1970: .infinity), now: start)
        }
        #expect(throws: TimeSinceError.duplicateReset) {
            try tracker.recordPreviousReset(at: start, now: start)
        }
        #expect(tracker == original)
    }

    @Test("Undo does not erase an intervening start edit or another early reset")
    func previousUndoPreservesEdits() throws {
        var tracker = TimeSinceTracker(name: "Coffee", startedAt: start)
        let change = try tracker.recordPreviousReset(at: start.addingTimeInterval(-60), now: start)
        try tracker.recordPreviousReset(at: start.addingTimeInterval(-30), now: start)
        tracker.undoPreviousReset(change)
        #expect(tracker.resets.count == 1)
        #expect(tracker.startedAt == start.addingTimeInterval(-60))
        try tracker.validate()
        let next = try tracker.recordPreviousReset(at: start.addingTimeInterval(-90), now: start)
        tracker.startedAt = start.addingTimeInterval(-120)
        tracker.undoPreviousReset(next)
        #expect(tracker.startedAt == start.addingTimeInterval(-120))
        try tracker.validate()
    }

    @Test("A scheduled tracker can record an earlier real occurrence")
    func backfillScheduledTracker() throws {
        var tracker = TimeSinceTracker(name: "Coffee", startedAt: start.addingTimeInterval(86_400))
        let original = tracker
        let change = try tracker.recordPreviousReset(at: start, now: start)
        #expect(!TimeSinceStatus(start: tracker.currentStart, now: start).isScheduled)
        tracker.undoPreviousReset(change)
        #expect(tracker == original)
    }
}
