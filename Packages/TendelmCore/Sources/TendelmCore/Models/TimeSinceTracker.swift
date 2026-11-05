import Foundation

public struct TimeSinceReset: Identifiable, Hashable, Codable, Sendable {
    public var id: UUID
    public var date: Date

    public init(id: UUID = UUID(), date: Date) {
        self.id = id
        self.date = date
    }
}

/// An elapsed-time tracker is independent of daily habit scores and schedules.
public struct TimeSinceTracker: Identifiable, Hashable, Codable, Sendable {
    public var id: UUID
    public var name: String
    public var startedAt: Date
    public var color: HabitColor
    public var resets: [TimeSinceReset]

    public init(id: UUID = UUID(), name: String, startedAt: Date = .now,
                color: HabitColor = .green, resets: [TimeSinceReset] = []) {
        self.id = id
        self.name = name
        self.startedAt = startedAt
        self.color = color
        self.resets = resets
    }

    public var orderedResets: [TimeSinceReset] {
        resets.sorted { $0.date == $1.date ? $0.id.uuidString < $1.id.uuidString : $0.date < $1.date }
    }

    public var currentStart: Date { max(startedAt, orderedResets.last?.date ?? startedAt) }

    public mutating func reset(at date: Date) throws {
        guard date >= currentStart else { throw TimeSinceError.clockMovedBackwards }
        resets.append(TimeSinceReset(date: date))
    }

    /// Backfill a real occurrence without replacing later history. An event
    /// before the initial start also moves that baseline back to keep it valid.
    @discardableResult
    public mutating func recordPreviousReset(at date: Date, now: Date = .now) throws -> PreviousResetChange {
        guard date.timeIntervalSince1970.isFinite, now.timeIntervalSince1970.isFinite,
              date <= now else { throw TimeSinceError.resetMustBeInPast }
        guard !resets.contains(where: { $0.date == date }) else { throw TimeSinceError.duplicateReset }
        let event = TimeSinceReset(date: date)
        let change = PreviousResetChange(reset: event, originalStart: startedAt, adjustedStart: min(startedAt, date))
        startedAt = change.adjustedStart
        resets.append(event)
        return change
    }

    /// Undo the event just backfilled, not whichever event is newest by date.
    public mutating func undoPreviousReset(_ change: PreviousResetChange) {
        guard resets.contains(change.reset) else { return }
        resets.removeAll { $0.id == change.reset.id }
        if startedAt == change.adjustedStart,
           resets.allSatisfy({ $0.date >= change.originalStart }) {
            startedAt = change.originalStart
        }
    }

    public mutating func undoLastReset() {
        guard let last = orderedResets.last else { return }
        resets.removeAll { $0.id == last.id }
    }

    public func validate() throws {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              startedAt.timeIntervalSince1970.isFinite,
              Set(resets.map(\.id)).count == resets.count,
              resets.allSatisfy({ $0.date.timeIntervalSince1970.isFinite && $0.date >= startedAt })
        else { throw TimeSinceError.invalidTracker }
    }
}

public enum TimeSinceError: Error, Equatable, Sendable {
    case clockMovedBackwards
    case invalidTracker
    case resetMustBeInPast
    case duplicateReset
}

public struct PreviousResetChange: Hashable, Sendable {
    public let reset: TimeSinceReset
    public let originalStart: Date
    public let adjustedStart: Date
}

/// A future start counts down; at its exact timestamp it becomes elapsed time.
/// This is derived from dates, so reopening the app requires no background work.
public struct TimeSinceStatus: Equatable, Sendable {
    public let isScheduled: Bool
    public let duration: ElapsedDuration

    public init(start: Date, now: Date) {
        isScheduled = now < start
        duration = isScheduled ? ElapsedDuration(from: now, to: start) : ElapsedDuration(from: start, to: now)
    }
}

/// A duration day is 24 elapsed hours, not a local calendar day. No running
/// background timer is needed: recompute from the saved absolute timestamp.
public struct ElapsedDuration: Equatable, Sendable {
    public let totalSeconds: Int
    public var days: Int { totalSeconds / 86_400 }
    public var hours: Int { (totalSeconds % 86_400) / 3_600 }
    public var minutes: Int { (totalSeconds % 3_600) / 60 }
    public var seconds: Int { totalSeconds % 60 }

    public init(from start: Date, to now: Date) {
        let elapsed = now.timeIntervalSince(start)
        // Bound malformed dates before conversion to avoid an integer trap.
        totalSeconds = elapsed.isFinite ? Int(min(max(0, elapsed), 315_576_000_000).rounded(.down)) : 0
    }
}
