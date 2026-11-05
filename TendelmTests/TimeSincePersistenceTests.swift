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
            configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)).usingExplicitTestSaves()
    }

    @Test("Deleting and undoing a history row restores its identity after saving")
    func deletedHistoryUndoRoundTrip() throws {
        let container = try memoryStore()
        let store = TimeSinceStore()
        var tracker = TimeSinceTracker(name: "Coffee", startedAt: start)
        try tracker.reset(at: start.addingTimeInterval(10))
        try tracker.reset(at: start.addingTimeInterval(20))
        try store.save(tracker, in: container.mainContext)
        let original = tracker.orderedResets
        let deleted = tracker.deleteReset(id: original[0].id)
        let event = try #require(deleted)
        try store.save(tracker, in: container.mainContext)
        let afterDelete = try #require(ModelContext(container).fetch(FetchDescriptor<TimeSinceRecord>()).first?.snapshot)
        #expect(afterDelete.orderedResets == [original[1]])
        let action = TimeSinceUndoAction(trackerID: tracker.id, change: .deleted(event))
        #expect(try action.undo(in: &tracker))
        try store.save(tracker, in: container.mainContext)
        let restored = try #require(ModelContext(container).fetch(FetchDescriptor<TimeSinceRecord>()).first?.snapshot)
        #expect(restored.orderedResets == original)
        #expect(restored.startedAt == start)
    }

    @Test("Backfilled history and its earlier baseline survive persistence and backups")
    func previousResetRoundTrip() throws {
        let container = try memoryStore()
        var tracker = TimeSinceTracker(name: "Scrolling", startedAt: start)
        try tracker.reset(at: start.addingTimeInterval(60))
        let change = try tracker.recordPreviousReset(at: start.addingTimeInterval(-60), now: start.addingTimeInterval(120))
        try TimeSinceStore().save(tracker, in: container.mainContext)
        let fresh = ModelContext(container)
        let saved = try #require(fresh.fetch(FetchDescriptor<TimeSinceRecord>()).first?.snapshot)
        #expect(saved.orderedResets == tracker.orderedResets)
        #expect(saved.startedAt == tracker.startedAt)
        let document = try DefaultBackupExporter().export(from: container.mainContext)
        let json = try DefaultBackupImporter().parse(data: DefaultBackupExporter().encode(document))
        let csv = try CSVBackupCoder().decode(CSVBackupCoder().encode(document))
        for decoded in [json, csv] {
            let restored = try #require(decoded.timeSinceTrackers.first)
            #expect(restored.orderedResets == tracker.orderedResets)
            #expect(restored.startedAt == tracker.startedAt)
        }
        tracker.undoPreviousReset(change)
        try TimeSinceStore().save(tracker, in: container.mainContext)
        let reloaded = try #require(ModelContext(container).fetch(FetchDescriptor<TimeSinceRecord>()).first?.snapshot)
        #expect(reloaded.startedAt == start)
        #expect(reloaded.orderedResets.map(\.date) == [start.addingTimeInterval(60)])
    }

    @Test("A future start persists exactly and survives both backup formats")
    func futureStartRoundTrip() throws {
        let container = try memoryStore()
        let future = Date(timeIntervalSince1970: (Date.now.timeIntervalSince1970 + 172_800).rounded())
        let tracker = TimeSinceTracker(name: "Starts later", startedAt: future)
        try TimeSinceStore().save(tracker, in: container.mainContext)
        let fresh = ModelContext(container)
        #expect(try fresh.fetch(FetchDescriptor<TimeSinceRecord>()).first?.snapshot == tracker)
        let document = BackupDocument(exportedAt: start, appVersion: "test", habits: [], timeSinceTrackers: [tracker])
        let json = try DefaultBackupExporter().encode(document)
        #expect(try DefaultBackupImporter().parse(data: json).timeSinceTrackers == [tracker])
        let csv = try CSVBackupCoder().encode(document)
        #expect(try CSVBackupCoder().decode(csv).timeSinceTrackers == [tracker])
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

    @Test("Restoring a tracker restores its history and keeps unrelated trackers")
    func restoreHistory() throws {
        let container = try memoryStore()
        var first = TimeSinceTracker(name: "One", startedAt: start)
        let second = TimeSinceTracker(name: "Two", startedAt: start)
        let backup = BackupDocument(exportedAt: start, appVersion: "test", habits: [], timeSinceTrackers: [first])
        try first.reset(at: start.addingTimeInterval(60))
        try TimeSinceStore().save(first, in: container.mainContext)
        try TimeSinceStore().save(second, in: container.mainContext)
        try DefaultBackupImporter().apply(backup, to: container.mainContext)
        let values = try container.mainContext.fetch(FetchDescriptor<TimeSinceRecord>()).map(\.snapshot)
        #expect(values.count == 2)
        #expect(values.first { $0.id == first.id }?.resets.isEmpty == true)
        #expect(values.first { $0.id == second.id } == second)
        #expect(try container.mainContext.fetchCount(FetchDescriptor<TimeSinceResetRecord>()) == 0)
    }

    @Test("An imported reset cannot reuse another tracker's identity")
    func conflictingResetID() throws {
        let container = try memoryStore()
        let event = TimeSinceReset(date: start.addingTimeInterval(60))
        let original = TimeSinceTracker(name: "Original", startedAt: start, resets: [event])
        try TimeSinceStore().save(original, in: container.mainContext)
        let conflict = TimeSinceTracker(name: "Other", startedAt: start, resets: [event])
        #expect(throws: TimeSinceError.invalidTracker) { try TimeSinceStore().save(conflict, in: container.mainContext) }
        #expect(try container.mainContext.fetchCount(FetchDescriptor<TimeSinceRecord>()) == 1)
        #expect(try container.mainContext.fetchCount(FetchDescriptor<TimeSinceResetRecord>()) == 1)
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
            let container = try ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)).usingExplicitTestSaves()
            let habit = TendelmSchemaV4.HabitRecord(name: "Read")
            container.mainContext.insert(habit)
            container.mainContext.insert(TendelmSchemaV4.CompletionRecord(date: start, habit: habit))
            try container.mainContext.save()
        }
        let tracker = TimeSinceTracker(name: "Scrolling", startedAt: start)
        do {
            let schema = Schema(versionedSchema: TendelmSchemaV5.self)
            let container = try ModelContainer(for: schema, migrationPlan: TendelmMigrationPlan.self,
                configurations: ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)).usingExplicitTestSaves()
            #expect(try container.mainContext.fetch(FetchDescriptor<HabitRecord>()).first?.name == "Read")
            #expect(try container.mainContext.fetchCount(FetchDescriptor<CompletionRecord>()) == 1)
            try TimeSinceStore().save(tracker, in: container.mainContext)
        }
        let schema = Schema(versionedSchema: TendelmSchemaV5.self)
        let reopened = try ModelContainer(for: schema, migrationPlan: TendelmMigrationPlan.self,
            configurations: ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)).usingExplicitTestSaves()
        #expect(try reopened.mainContext.fetch(FetchDescriptor<TimeSinceRecord>()).first?.snapshot == tracker)
    }
}
