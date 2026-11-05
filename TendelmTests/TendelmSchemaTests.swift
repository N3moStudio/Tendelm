import Testing
import Foundation
import SwiftData
@testable import Tendelm
import TendelmCore

@Suite("TendelmSchema + TendelmMigrationPlan")
@MainActor
struct TendelmSchemaTests {
    @Test("V1 version identifier is 1.0.0")
    func v1Version() {
        #expect(TendelmSchemaV1.versionIdentifier == Schema.Version(1, 0, 0))
    }

    @Test("V2 version identifier is 2.0.0")
    func v2Version() {
        #expect(TendelmSchemaV2.versionIdentifier == Schema.Version(2, 0, 0))
    }

    @Test("V3 version identifier is 3.0.0")
    func v3Version() {
        #expect(TendelmSchemaV3.versionIdentifier == Schema.Version(3, 0, 0))
    }

    @Test("V4 version identifier is 4.0.0")
    func v4Version() {
        #expect(TendelmSchemaV4.versionIdentifier == Schema.Version(4, 0, 0))
    }

    @Test("Migration plan declares V1→V2, V2→V3, and V3→V4 lightweight stages")
    func migrationPlanShape() {
        #expect(TendelmMigrationPlan.schemas.count == 5)
        #expect(TendelmMigrationPlan.stages.count == 4)
    }

    @Test("In-memory ModelContainer constructs from the current (V4) schema")
    func containerBuildsFromPlan() throws {
        let schema = Schema(versionedSchema: TendelmSchemaV5.self)
        let container = try ModelContainer(
            for: schema,
            migrationPlan: TendelmMigrationPlan.self,
            configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        )
        let habit = HabitRecord(name: "Smoke")
        container.mainContext.insert(habit)
        try container.mainContext.save()
        let fetched = try container.mainContext.fetch(FetchDescriptor<HabitRecord>())
        #expect(fetched.count == 1)
    }

    @Test("Lightweight migration from V1 populates default color and icon")
    func v1ToV2Migration() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("migration-test-\(UUID().uuidString).store")
        defer { try? FileManager.default.removeItem(at: url) }

        // Step 1: open a V1 store at the temp URL and insert a habit.
        do {
            let schema = Schema(versionedSchema: TendelmSchemaV1.self)
            let config = ModelConfiguration(schema: schema, url: url)
            let container = try ModelContainer(
                for: schema,
                migrationPlan: nil,
                configurations: config
            )
            let habit = TendelmSchemaV1.HabitRecord(name: "Pre-migration habit")
            container.mainContext.insert(habit)
            try container.mainContext.save()
        }

        // Step 2: reopen as V2 + migration plan; lightweight migration runs.
        let schema = Schema(versionedSchema: TendelmSchemaV2.self)
        let config = ModelConfiguration(schema: schema, url: url)
        let container = try ModelContainer(
            for: schema,
            migrationPlan: TendelmMigrationPlan.self,
            configurations: config
        )
        let habits = try container.mainContext.fetch(FetchDescriptor<TendelmSchemaV2.HabitRecord>())
        #expect(habits.count == 1)
        let habit = try #require(habits.first)
        #expect(habit.name == "Pre-migration habit")
        #expect(habit.color == .blue)
        #expect(habit.icon == HabitIcon.default)
    }

    @Test("Lightweight migration from V2 populates default reminder fields")
    func v2ToV3Migration() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("migration-test-\(UUID().uuidString).store")
        defer { try? FileManager.default.removeItem(at: url) }

        // Step 1: seed a V2 store.
        do {
            let schema = Schema(versionedSchema: TendelmSchemaV2.self)
            let config = ModelConfiguration(schema: schema, url: url)
            let container = try ModelContainer(
                for: schema,
                migrationPlan: nil,
                configurations: config
            )
            let habit = TendelmSchemaV2.HabitRecord(name: "V2 habit", color: .orange)
            container.mainContext.insert(habit)
            try container.mainContext.save()
        }

        // Step 2: reopen as V3; lightweight stage fills reminder defaults.
        let schema = Schema(versionedSchema: TendelmSchemaV3.self)
        let config = ModelConfiguration(schema: schema, url: url)
        let container = try ModelContainer(
            for: schema,
            migrationPlan: TendelmMigrationPlan.self,
            configurations: config
        )
        let habits = try container.mainContext.fetch(FetchDescriptor<TendelmSchemaV3.HabitRecord>())
        #expect(habits.count == 1)
        let habit = try #require(habits.first)
        #expect(habit.name == "V2 habit")
        #expect(habit.color == .orange)
        #expect(habit.remindersEnabled == false)
        #expect(habit.reminderHour == 9)
        #expect(habit.reminderMinute == 0)
    }

    @Test("Lightweight migration from V3 populates default sortOrder")
    func v3ToV4Migration() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("migration-test-\(UUID().uuidString).store")
        defer { try? FileManager.default.removeItem(at: url) }

        // Step 1: seed a V3 store.
        do {
            let schema = Schema(versionedSchema: TendelmSchemaV3.self)
            let config = ModelConfiguration(schema: schema, url: url)
            let container = try ModelContainer(
                for: schema,
                migrationPlan: nil,
                configurations: config
            )
            let habit = TendelmSchemaV3.HabitRecord(name: "V3 habit", color: .green)
            container.mainContext.insert(habit)
            try container.mainContext.save()
        }

        // Step 2: reopen as V4; lightweight stage fills sortOrder default.
        let schema = Schema(versionedSchema: TendelmSchemaV4.self)
        let config = ModelConfiguration(schema: schema, url: url)
        let container = try ModelContainer(
            for: schema,
            migrationPlan: TendelmMigrationPlan.self,
            configurations: config
        )
        let habits = try container.mainContext.fetch(FetchDescriptor<TendelmSchemaV4.HabitRecord>())
        #expect(habits.count == 1)
        let habit = try #require(habits.first)
        #expect(habit.name == "V3 habit")
        #expect(habit.color == .green)
        #expect(habit.sortOrder == 0)
    }
}
