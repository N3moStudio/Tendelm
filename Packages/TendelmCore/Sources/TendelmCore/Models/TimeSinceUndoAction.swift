import Foundation

/// One short-lived inverse operation, never an undo stack or a saved tracker snapshot.
public struct TimeSinceUndoAction: Identifiable, Sendable {
    public enum Change: Sendable {
        case added(PreviousResetChange)
        case deleted(TimeSinceReset)
    }

    public let id = UUID()
    public let trackerID: UUID
    public let change: Change
    public let deadline: ContinuousClock.Instant

    public init(trackerID: UUID, change: Change, now: ContinuousClock.Instant = .now,
                lifetime: Duration = .seconds(6)) {
        self.trackerID = trackerID
        self.change = change
        deadline = now.advanced(by: lifetime)
    }

    /// A delayed tap or a resumed app cannot undo an expired action.
    @discardableResult
    public func undo(in tracker: inout TimeSinceTracker, now: ContinuousClock.Instant = .now) throws -> Bool {
        guard now < deadline, tracker.id == trackerID else { return false }
        switch change {
        case .added(let receipt):
            guard tracker.resets.contains(receipt.reset) else { return false }
            tracker.undoPreviousReset(receipt)
        case .deleted(let event):
            guard !tracker.resets.contains(event) else { return false }
            try tracker.restoreReset(event)
        }
        return true
    }
}
