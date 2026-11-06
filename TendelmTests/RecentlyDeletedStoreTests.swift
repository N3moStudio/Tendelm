import Foundation
import SwiftData
import Testing
@testable import Tendelm
import TendelmCore

@Suite("Recently Deleted recovery") @MainActor
struct RecentlyDeletedStoreTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000.125)
    private let store = RecentlyDeletedStore()
    private enum SaveFailure: Error { case simulated }

    private func container(url: URL? = nil, v5: Bool = false) throws -> ModelContainer {
        let schema = v5 ? Schema(versionedSchema: TendelmSchemaV5.self) : Schema(versionedSchema: TendelmSchemaV6.self)
        let configuration: ModelConfiguration
        if let url { configuration = ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none) }
        else { configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none) }
        return try ModelContainer(for: schema, migrationPlan: v5 ? nil : TendelmMigrationPlan.self,
            configurations: configuration).usingExplicitTestSaves()
    }

    private func seed(_ context: ModelContext) throws -> (Habit, Completion, TimeSinceTracker) {
        let habit = HabitRecord(name: "Read slowly", createdAt: now.addingTimeInterval(-1_000),
            archivedAt: now.addingTimeInterval(-50), color: .orange, icon: "book",
            remindersEnabled: true, reminderHour: 17, reminderMinute: 25, sortOrder: 9)
        context.insert(habit)
        let completion = CompletionRecord(date: now.addingTimeInterval(-500), value: 3.5, note: "A calm day", habit: habit)
        context.insert(completion)
        var tracker = TimeSinceTracker(name: "Scrolling", startedAt: now.addingTimeInterval(-900), color: .blue)
        try tracker.reset(at: now.addingTimeInterval(-100))
        try TimeSinceStore().upsert(tracker, in: context)
        try context.save()
        return (habit.snapshot, try #require(completion.snapshot), tracker)
    }

    @Test("V5 disk migration and recovery preserve every field and child identity")
    func migrationAndDiskRecovery() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("migration.sqlite")
        let original: (Habit, Completion, TimeSinceTracker)
        do {
            let old = try container(url: url, v5: true)
            original = try seed(old.mainContext)
        }
        do {
            let migrated = try container(url: url)
            let context = migrated.mainContext
            let restoredHabit = try #require(context.fetch(FetchDescriptor<HabitRecord>()).first)
            #expect(HabitBackup(habit: restoredHabit.snapshot, completions: (restoredHabit.completions ?? []).compactMap(\.snapshot))
                == HabitBackup(habit: original.0, completions: [original.1]))
            #expect(restoredHabit.sortOrder == original.0.sortOrder)
            #expect(try context.fetch(FetchDescriptor<TimeSinceRecord>()).first?.snapshot == original.2)
            try store.moveHabit(id: original.0.id, in: context, now: now)
            try store.moveTracker(id: original.2.id, in: context, now: now)
            #expect(try context.fetchCount(FetchDescriptor<HabitRecord>()) == 0)
            #expect(try context.fetchCount(FetchDescriptor<CompletionRecord>()) == 0)
            #expect(try context.fetchCount(FetchDescriptor<TimeSinceResetRecord>()) == 0)
            let backup = try DefaultBackupExporter().export(from: context)
            #expect(backup.habits.isEmpty && backup.timeSinceTrackers.isEmpty)
        }
        do {
            let reopened = try container(url: url)
            let context = reopened.mainContext
            let ids = Set(try context.fetch(FetchDescriptor<RecentlyDeletedRecord>()).map(\.id))
            #expect(ids.count == 2)
            try store.restore(ids: ids, in: context, now: now.addingTimeInterval(60))
            let restoredHabit = try #require(context.fetch(FetchDescriptor<HabitRecord>()).first)
            #expect(HabitBackup(habit: restoredHabit.snapshot, completions: (restoredHabit.completions ?? []).compactMap(\.snapshot))
                == HabitBackup(habit: original.0, completions: [original.1]))
            #expect(restoredHabit.sortOrder == original.0.sortOrder)
            #expect(try context.fetch(FetchDescriptor<CompletionRecord>()).first?.snapshot == original.1)
            #expect(try context.fetch(FetchDescriptor<TimeSinceRecord>()).first?.snapshot == original.2)
            #expect(try context.fetchCount(FetchDescriptor<RecentlyDeletedRecord>()) == 0)
        }
    }

    @Test("Failed delete, restore and permanent delete roll back both sides")
    func saveFailuresKeepRecovery() throws {
        let db = try container()
        let context = db.mainContext
        let original = try seed(context)
        let failing = RecentlyDeletedStore(persist: { _ in throw SaveFailure.simulated })
        #expect(throws: SaveFailure.self) { try failing.moveHabit(id: original.0.id, in: context, now: now) }
        #expect(try context.fetchCount(FetchDescriptor<HabitRecord>()) == 1)
        #expect(try context.fetchCount(FetchDescriptor<CompletionRecord>()) == 1)
        #expect(try context.fetchCount(FetchDescriptor<RecentlyDeletedRecord>()) == 0)
        try store.moveHabit(id: original.0.id, in: context, now: now)
        let id = try #require(context.fetch(FetchDescriptor<RecentlyDeletedRecord>()).first?.id)
        #expect(throws: SaveFailure.self) { try failing.restore(ids: [id], in: context, now: now) }
        #expect(try context.fetchCount(FetchDescriptor<HabitRecord>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<RecentlyDeletedRecord>()) == 1)
        #expect(throws: SaveFailure.self) { try failing.permanentlyDelete(ids: [id], in: context) }
        #expect(try context.fetchCount(FetchDescriptor<RecentlyDeletedRecord>()) == 1)
        #expect(try context.fetch(FetchDescriptor<TimeSinceRecord>()).first?.snapshot == original.2)
    }

    @Test("Identity conflicts and corrupt entries leave the entire restore selection untouched")
    func conflictAndCorruption() throws {
        let db = try container()
        let context = db.mainContext
        let original = try seed(context)
        try store.moveHabit(id: original.0.id, in: context, now: now)
        try store.moveTracker(id: original.2.id, in: context, now: now)
        let entries = try context.fetch(FetchDescriptor<RecentlyDeletedRecord>())
        let ids = Set(entries.map(\.id))
        let duplicate = HabitRecord(id: original.0.id, name: "Imported copy")
        context.insert(duplicate)
        try context.save()
        #expect(throws: RecentlyDeletedStore.Failure.self) { try store.restore(ids: ids, in: context, now: now) }
        #expect(try context.fetchCount(FetchDescriptor<TimeSinceRecord>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<RecentlyDeletedRecord>()) == 2)
        #expect(duplicate.name == "Imported copy")
        context.delete(duplicate)
        entries[0].payload = Data("broken".utf8)
        try context.save()
        #expect(throws: RecentlyDeletedStore.Failure.self) { try store.restore(ids: ids, in: context, now: now) }
        #expect(try context.fetchCount(FetchDescriptor<HabitRecord>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<RecentlyDeletedRecord>()) == 2)
    }

    @Test("Delete All uses confirmed IDs and never consumes a later deletion")
    func confirmedSelection() throws {
        let db = try container()
        let context = db.mainContext
        let original = try seed(context)
        try store.moveHabit(id: original.0.id, in: context, now: now)
        let confirmed = Set(try context.fetch(FetchDescriptor<RecentlyDeletedRecord>()).map(\.id))
        try store.moveTracker(id: original.2.id, in: context, now: now)
        try store.permanentlyDelete(ids: confirmed, in: context)
        let remaining = try context.fetch(FetchDescriptor<RecentlyDeletedRecord>())
        #expect(remaining.count == 1 && remaining.first?.name == original.2.name)
        #expect(throws: RecentlyDeletedStore.Failure.self) { try store.permanentlyDelete(ids: confirmed, in: context) }
        #expect(try context.fetchCount(FetchDescriptor<RecentlyDeletedRecord>()) == 1)
    }

    @Test("The 30-day boundary expires recovery, pruning only expired entries")
    func expiration() throws {
        let db = try container()
        let context = db.mainContext
        let original = try seed(context)
        try store.moveHabit(id: original.0.id, in: context, now: now)
        try store.moveTracker(id: original.2.id, in: context, now: now.addingTimeInterval(60))
        let entry = try #require(context.fetch(FetchDescriptor<RecentlyDeletedRecord>()).first(where: { $0.kind == "Habit" }))
        #expect(entry.expiresAt == now.addingTimeInterval(30 * 86_400))
        #expect(throws: RecentlyDeletedStore.Failure.self) { try store.restore(ids: [entry.id], in: context, now: entry.expiresAt) }
        try store.prune(in: context, now: entry.expiresAt)
        #expect(try context.fetchCount(FetchDescriptor<RecentlyDeletedRecord>()) == 1)
    }

    @Test("Full erasure includes histories and recovery copies, and is repeatable")
    func eraseEverything() throws {
        let db = try container()
        let context = db.mainContext
        let original = try seed(context)
        try store.moveHabit(id: original.0.id, in: context, now: now)
        context.insert(HabitRecord(name: "Keep until full erasure"))
        try context.save()
        let failing = RecentlyDeletedStore(persist: { _ in throw SaveFailure.simulated })
        #expect(throws: SaveFailure.self) { try failing.eraseRecords(in: context) }
        #expect(try context.fetchCount(FetchDescriptor<RecentlyDeletedRecord>()) == 1)
        #expect(try context.fetchCount(FetchDescriptor<TimeSinceResetRecord>()) == 1)
        try store.eraseRecords(in: context)
        try store.eraseRecords(in: context)
        #expect(try context.fetchCount(FetchDescriptor<HabitRecord>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<CompletionRecord>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<TimeSinceRecord>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<TimeSinceResetRecord>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<RecentlyDeletedRecord>()) == 0)
    }

    @Test("Recovery operations refuse to discard an unrelated unfinished edit")
    func pendingEdits() throws {
        let db = try container()
        let original = try seed(db.mainContext)
        db.mainContext.insert(HabitRecord(name: "Unsaved edit"))
        #expect(throws: RecentlyDeletedStore.Failure.self) { try store.moveHabit(id: original.0.id, in: db.mainContext, now: now) }
        #expect(db.mainContext.hasChanges)
        #expect(try db.mainContext.fetchCount(FetchDescriptor<RecentlyDeletedRecord>()) == 0)
    }
}
