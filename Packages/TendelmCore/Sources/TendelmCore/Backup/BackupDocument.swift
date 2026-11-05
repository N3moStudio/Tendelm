import Foundation

/// Root of the JSON backup format exchanged by export / import.
///
/// The wire shape is decoupled from the SwiftData schema on purpose:
/// a schema bump that renames or reshapes `HabitRecord` must not
/// silently change what a previously exported file means. Bump
/// `formatVersion` and migrate explicitly.
public struct BackupDocument: Hashable, Codable, Sendable {
    /// Current format version written by this app. Importers compare
    /// against `BackupDocument.currentFormatVersion` and refuse files
    /// with a higher value than they understand.
    public static let currentFormatVersion = 2

    public var formatVersion: Int
    public var exportedAt: Date
    public var appVersion: String
    public var habits: [HabitBackup]
    public var timeSinceTrackers: [TimeSinceTracker]

    public init(
        formatVersion: Int = BackupDocument.currentFormatVersion,
        exportedAt: Date,
        appVersion: String,
        habits: [HabitBackup],
        timeSinceTrackers: [TimeSinceTracker] = []
    ) {
        self.formatVersion = formatVersion
        self.exportedAt = exportedAt
        self.appVersion = appVersion
        self.habits = habits
        self.timeSinceTrackers = timeSinceTrackers
    }

    private enum CodingKeys: String, CodingKey {
        case formatVersion, exportedAt, appVersion, habits, timeSinceTrackers
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        formatVersion = try values.decode(Int.self, forKey: .formatVersion)
        exportedAt = try values.decode(Date.self, forKey: .exportedAt)
        appVersion = try values.decode(String.self, forKey: .appVersion)
        habits = try values.decode([HabitBackup].self, forKey: .habits)
        timeSinceTrackers = try values.decodeIfPresent([TimeSinceTracker].self, forKey: .timeSinceTrackers) ?? []
    }

    public func validateTrackers() throws {
        guard (1...Self.currentFormatVersion).contains(formatVersion) else {
            throw BackupError.unsupportedVersion(formatVersion)
        }
        guard Set(timeSinceTrackers.map(\.id)).count == timeSinceTrackers.count else {
            throw BackupError.invalidJSON
        }
        var resetIDs = Set<UUID>()
        for tracker in timeSinceTrackers {
            try tracker.validate()
            for reset in tracker.resets {
                guard resetIDs.insert(reset.id).inserted else { throw BackupError.invalidJSON }
            }
        }
    }
}
