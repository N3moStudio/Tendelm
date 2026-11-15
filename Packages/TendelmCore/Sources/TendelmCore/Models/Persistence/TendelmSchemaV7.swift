import Foundation
import SwiftData

/// Adds optional tracker ordering; existing trackers keep their chronological order.
public enum TendelmSchemaV7: VersionedSchema {
    public static let versionIdentifier = Schema.Version(7, 0, 0)
    public static var models: [any PersistentModel.Type] {
        [TendelmSchemaV5.HabitRecord.self, TendelmSchemaV5.CompletionRecord.self,
         TimeSinceRecord.self, TimeSinceResetRecord.self, TendelmSchemaV6.RecentlyDeletedRecord.self]
    }
}

public extension TendelmSchemaV7 {
    @Model
    public final class TimeSinceRecord {
        public var id: UUID = UUID()
        public var name: String = ""
        public var startedAt: Date = Date()
        public var sortOrder: Int? = nil
        private var colorRaw: String = "green"
        @Relationship(deleteRule: .cascade, inverse: \TimeSinceResetRecord.tracker)
        public var resets: [TimeSinceResetRecord]? = []
        public init(id: UUID = UUID(), name: String = "", startedAt: Date = .now, color: HabitColor = .green) {
            self.id = id
            self.name = name
            self.startedAt = startedAt
            self.colorRaw = color.rawValue
        }
        public var color: HabitColor {
            get { HabitColor(rawValue: colorRaw) ?? .green }
            set { colorRaw = newValue.rawValue }
        }
        public var snapshot: TimeSinceTracker {
            TimeSinceTracker(id: id, name: name, startedAt: startedAt, color: color,
                resets: (resets ?? []).map { TimeSinceReset(id: $0.id, date: $0.date) }, sortOrder: sortOrder)
        }
    }
    @Model
    public final class TimeSinceResetRecord {
        public var id: UUID = UUID()
        public var date: Date = Date()
        public var tracker: TimeSinceRecord?
        public init(id: UUID = UUID(), date: Date = .now, tracker: TimeSinceRecord? = nil) {
            self.id = id
            self.date = date
            self.tracker = tracker
        }
    }
}
public typealias TimeSinceRecord = TendelmSchemaV7.TimeSinceRecord
public typealias TimeSinceResetRecord = TendelmSchemaV7.TimeSinceResetRecord
