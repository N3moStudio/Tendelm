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
