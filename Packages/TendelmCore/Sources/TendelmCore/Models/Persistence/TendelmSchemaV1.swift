import Foundation
import SwiftData

/// Version 1 of Tendelm's persistent schema. Subsequent schema versions
/// (`TendelmSchemaV2`, …) live alongside this one — never modify a
/// shipped version in place; CloudKit treats schema changes as
/// breaking and migrations rely on the prior version's snapshot.
public enum TendelmSchemaV1: VersionedSchema {
    public static let versionIdentifier = Schema.Version(1, 0, 0)

    public static var models: [any PersistentModel.Type] {
        [HabitRecord.self, CompletionRecord.self]
    }
}
