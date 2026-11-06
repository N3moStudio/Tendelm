import Foundation
import SwiftData

/// Adds a recovery bin without changing the shipped habit/tracker entities.
public enum TendelmSchemaV6: VersionedSchema {
    public static let versionIdentifier = Schema.Version(6, 0, 0)
    public static var models: [any PersistentModel.Type] {
        TendelmSchemaV5.models + [RecentlyDeletedRecord.self]
    }

    @Model
    public final class RecentlyDeletedRecord {
        public var id: UUID = UUID()
        public var deletedAt: Date = Date()
        public var name: String = ""
        public var kind: String = ""
        public var payload: Data = Data()

        public init(id: UUID = UUID(), deletedAt: Date, name: String, kind: String, payload: Data) {
            self.id = id
            self.deletedAt = deletedAt
            self.name = name
            self.kind = kind
            self.payload = payload
        }

        public var expiresAt: Date { deletedAt.addingTimeInterval(30 * 24 * 60 * 60) }
    }
}

public typealias RecentlyDeletedRecord = TendelmSchemaV6.RecentlyDeletedRecord
