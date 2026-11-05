import Foundation
import SwiftData
import Testing
import TendelmCore

@Suite("Time since persistence and backups") @MainActor
struct TimeSincePersistenceTests {
    private let start = Date(timeIntervalSince1970: 1_700_000_000)
    private func memoryStore() throws -> ModelContainer {
        let schema = Schema(versionedSchema: TendelmSchemaV5.self)
        return try ModelContainer(for: schema, migrationPlan: TendelmMigrationPlan.self,
            configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none))
    }

    @Test("Reset, undo and deletion persist without changing another tracker")
    func saveUndoAndDelete() throws {
        let container = try memoryStore()
        let context = container.mainContext
        let store = TimeSinceStore()
        var first = TimeSinceTracker(name: "Scrolling", startedAt: start)
        let second = TimeSinceTracker(name: "Biting nails", startedAt: start)
        try store.save(first, in: context)
        try store.save(second, in: context)
        try first.reset(at: start.addingTimeInterval(3600))
        try store.save(first, in: context)
        #expect(try context.fetchCount(FetchDescriptor<TimeSinceResetRecord>()) == 1)
        let fresh = ModelContext(container)
        let snapshots = try fresh.fetch(FetchDescriptor<TimeSinceRecord>()).map(\.snapshot)
        #expect(snapshots.first { $0.id == first.id }?.currentStart == first.currentStart)
        #expect(snapshots.first { $0.id == second.id }?.currentStart == start)
        first.undoLastReset()
        try store.save(first, in: context)
        #expect(try context.fetchCount(FetchDescriptor<TimeSinceResetRecord>()) == 0)
        try first.reset(at: start.addingTimeInterval(7200))
        try store.save(first, in: context)
        try store.delete(id: first.id, in: context)
        #expect(try context.fetchCount(FetchDescriptor<TimeSinceResetRecord>()) == 0)
        #expect(try context.fetch(FetchDescriptor<TimeSinceRecord>()).map(\.id) == [second.id])
    }

    @Test("JSON and CSV round-trip multiple trackers, reset history and special names")
    func backupRoundTrip() throws {
        let source = try memoryStore()
        var first = TimeSinceTracker(name: "Tea, \"late\"\n🌿", startedAt: start, color: .teal)
        try first.reset(at: start.addingTimeInterval(600))
        try first.reset(at: start.addingTimeInterval(3600))
        let second = TimeSinceTracker(name: "Scrolling", startedAt: start, color: .purple)
        try TimeSinceStore().save(first, in: source.mainContext)
        try TimeSinceStore().save(second, in: source.mainContext)
        let exporter = DefaultBackupExporter()
        let document = try exporter.export(from: source.mainContext)
        let json = try DefaultBackupImporter().parse(data: exporter.encode(document))
        let csv = try CSVBackupCoder().decode(CSVBackupCoder().encode(document))
        for decoded in [json, csv] {
            let destination = try memoryStore()
            let summary = try DefaultBackupImporter().apply(decoded, to: destination.mainContext)
            #expect(summary.newTrackers == 2)
            let values = try destination.mainContext.fetch(FetchDescriptor<TimeSinceRecord>()).map(\.snapshot)
            #expect(values.first { $0.id == first.id }?.orderedResets == first.orderedResets)
            #expect(values.first { $0.id == first.id }?.name == first.name)
            #expect(values.first { $0.id == second.id }?.color == .purple)
            let repeatSummary = try DefaultBackupImporter().apply(decoded, to: destination.mainContext)
            #expect(repeatSummary.updatedTrackers == 2)
            #expect(try destination.mainContext.fetchCount(FetchDescriptor<TimeSinceResetRecord>()) == 2)
        }
    }

    @Test("Old JSON without trackers remains readable")
    func legacyBackup() throws {
        let json = #"{"formatVersion":1,"exportedAt":"2023-11-14T22:13:20Z","appVersion":"1.14","habits":[]}"#
        #expect(try DefaultBackupImporter().parse(data: Data(json.utf8)).timeSinceTrackers.isEmpty)
    }

    @Test("Invalid backup is rejected before touching existing data")
    func rejectInvalid() throws {
        let container = try memoryStore()
        let original = TimeSinceTracker(name: "Original", startedAt: start)
        try TimeSinceStore().save(original, in: container.mainContext)
        var changed = original
        changed.name = "Changed"
        let invalid = TimeSinceTracker(name: "Bad history", startedAt: start,
            resets: [TimeSinceReset(date: start.addingTimeInterval(-60))])
        let backup = BackupDocument(exportedAt: start, appVersion: "test", habits: [], timeSinceTrackers: [changed, invalid])
        #expect(throws: (any Error).self) { try DefaultBackupImporter().apply(backup, to: container.mainContext) }
        #expect(try container.mainContext.fetch(FetchDescriptor<TimeSinceRecord>()).first?.name == "Original")
    }

    @Test("V4 disk store upgrades to V5, retaining habit history and saved timers on reopen")
    func migrationAndReopen() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("migration.store")
        do {
            let schema = Schema(versionedSchema: TendelmSchemaV4.self)
            let container = try ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none))
            let habit = TendelmSchemaV4.HabitRecord(name: "Read")
            container.mainContext.insert(habit)
            container.mainContext.insert(TendelmSchemaV4.CompletionRecord(date: start, habit: habit))
            try container.mainContext.save()
        }
        let tracker = TimeSinceTracker(name: "Scrolling", startedAt: start)
        do {
            let schema = Schema(versionedSchema: TendelmSchemaV5.self)
            let container = try ModelContainer(for: schema, migrationPlan: TendelmMigrationPlan.self,
                configurations: ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none))
            #expect(try container.mainContext.fetch(FetchDescriptor<HabitRecord>()).first?.name == "Read")
            #expect(try container.mainContext.fetchCount(FetchDescriptor<CompletionRecord>()) == 1)
            try TimeSinceStore().save(tracker, in: container.mainContext)
        }
        let schema = Schema(versionedSchema: TendelmSchemaV5.self)
        let reopened = try ModelContainer(for: schema, migrationPlan: TendelmMigrationPlan.self,
            configurations: ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none))
        #expect(try reopened.mainContext.fetch(FetchDescriptor<TimeSinceRecord>()).first?.snapshot == tracker)
    }
}
