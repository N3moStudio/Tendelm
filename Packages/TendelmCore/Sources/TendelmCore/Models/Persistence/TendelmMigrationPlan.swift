import Foundation
import SwiftData

/// Migration plan for Tendelm's persistent schema. Schemas are listed
/// oldest-to-newest; `stages` bridges each consecutive pair.
public enum TendelmMigrationPlan: SchemaMigrationPlan {
    public static var schemas: [any VersionedSchema.Type] {
        [TendelmSchemaV1.self, TendelmSchemaV2.self, TendelmSchemaV3.self, TendelmSchemaV4.self, TendelmSchemaV5.self, TendelmSchemaV6.self]
    }

    public static var stages: [MigrationStage] {
        [
            .lightweight(
                fromVersion: TendelmSchemaV1.self,
                toVersion: TendelmSchemaV2.self
            ),
            .lightweight(
                fromVersion: TendelmSchemaV2.self,
                toVersion: TendelmSchemaV3.self
            ),
            .lightweight(
                fromVersion: TendelmSchemaV3.self,
                toVersion: TendelmSchemaV4.self
            ),
            .lightweight(fromVersion: TendelmSchemaV4.self, toVersion: TendelmSchemaV5.self),
            .lightweight(fromVersion: TendelmSchemaV5.self, toVersion: TendelmSchemaV6.self)
        ]
    }
}
