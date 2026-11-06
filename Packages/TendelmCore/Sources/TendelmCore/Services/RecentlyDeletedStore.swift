import Foundation
import SwiftData

/// The recovery copy and removal of the live item commit in one database save.
/// A failed save rolls both back. Nothing is written to a separate sidecar file.
@MainActor
public struct RecentlyDeletedStore {
    private let persist: (ModelContext) throws -> Void
    public init(persist: @escaping (ModelContext) throws -> Void = { try $0.save() }) {
        self.persist = persist
    }

    private struct Payload: Codable {
        var version = 1
        var habit: HabitBackup?
        var sortOrder: Int?
        var tracker: TimeSinceTracker?
    }

    public enum Failure: Error, LocalizedError {
        case pendingChanges, full, invalid, expired, exists, selectionChanged
        public var errorDescription: String? {
            switch self {
            case .pendingChanges: "Finish your current edit, then try again."
            case .full: "Recently Deleted is full. Permanently delete an item there first."
            case .invalid: "This recovery copy couldn't be read. It was kept."
            case .expired: "This item has reached the end of its 30-day recovery period."
            case .exists: "An item with this identity is already saved. Nothing was replaced."
            case .selectionChanged: "The selection changed. Review the items and try again."
            }
        }
    }

    public func moveHabit(id: UUID, in context: ModelContext, now: Date = .now) throws {
        try requireClean(context)
        guard let record = try context.fetch(FetchDescriptor<HabitRecord>()).first(where: { $0.id == id }) else { return }
        let habit = HabitBackup(habit: record.snapshot, completions: (record.completions ?? []).compactMap(\.snapshot))
        let data = try JSONEncoder().encode(Payload(habit: habit, sortOrder: record.sortOrder))
        try checkRoom(in: context, now: now)
        try commit(in: context) {
            context.insert(RecentlyDeletedRecord(deletedAt: now, name: record.name, kind: "Habit", payload: data))
            context.delete(record)
        }
    }

    public func moveTracker(id: UUID, in context: ModelContext, now: Date = .now) throws {
        try requireClean(context)
        guard let record = try context.fetch(FetchDescriptor<TimeSinceRecord>()).first(where: { $0.id == id }) else { return }
        let data = try JSONEncoder().encode(Payload(tracker: record.snapshot))
        try checkRoom(in: context, now: now)
        try commit(in: context) {
            context.insert(RecentlyDeletedRecord(deletedAt: now, name: record.name, kind: "Time since", payload: data))
            context.delete(record)
        }
    }

    public func restore(ids: Set<UUID>, in context: ModelContext, now: Date = .now) throws {
        try requireClean(context)
        let entries = try selected(ids, in: context)
        var habits = Set(try context.fetch(FetchDescriptor<HabitRecord>()).map(\.id))
        var completions = Set(try context.fetch(FetchDescriptor<CompletionRecord>()).map(\.id))
        var trackers = Set(try context.fetch(FetchDescriptor<TimeSinceRecord>()).map(\.id))
        var resets = Set(try context.fetch(FetchDescriptor<TimeSinceResetRecord>()).map(\.id))
        // Validate the complete selection before staging any restores.
        let payloads = try entries.map { entry -> Payload in
            guard entry.expiresAt > now else { throw Failure.expired }
            guard let value = try? JSONDecoder().decode(Payload.self, from: entry.payload), value.version == 1,
                  (value.habit == nil) != (value.tracker == nil) else { throw Failure.invalid }
            if let habit = value.habit {
                guard habits.insert(habit.id).inserted else { throw Failure.exists }
                for completion in habit.completions {
                    guard completions.insert(completion.id).inserted else { throw Failure.exists }
                }
            }
            if let tracker = value.tracker {
                try tracker.validate()
                guard trackers.insert(tracker.id).inserted else { throw Failure.exists }
                for reset in tracker.resets {
                    guard resets.insert(reset.id).inserted else { throw Failure.exists }
                }
            }
            return value
        }
        try commit(in: context) {
            for payload in payloads {
                if let habit = payload.habit {
                    let record = HabitRecord(id: habit.id, name: habit.name, frequency: habit.frequency,
                        type: habit.type, createdAt: habit.createdAt, archivedAt: habit.archivedAt,
                        color: habit.color, icon: habit.icon, remindersEnabled: habit.remindersEnabled,
                        reminderHour: habit.reminderHour, reminderMinute: habit.reminderMinute,
                        sortOrder: payload.sortOrder ?? 0)
                    context.insert(record)
                    for day in habit.completions {
                        context.insert(CompletionRecord(id: day.id, date: day.date, value: day.value, note: day.note, habit: record))
                    }
                }
                if let tracker = payload.tracker { try TimeSinceStore().upsert(tracker, in: context) }
            }
            for entry in entries { context.delete(entry) }
        }
    }

    /// IDs are captured when the confirmation opens: newly deleted items cannot
    /// silently enter a pending Delete All operation.
    public func permanentlyDelete(ids: Set<UUID>, in context: ModelContext) throws {
        try requireClean(context)
        let entries = try selected(ids, in: context)
        try commit(in: context) { for entry in entries { context.delete(entry) } }
    }

    public func prune(in context: ModelContext, now: Date = .now) throws {
        try requireClean(context)
        let expired = try context.fetch(FetchDescriptor<RecentlyDeletedRecord>()).filter { $0.expiresAt <= now }
        guard !expired.isEmpty else { return }
        try commit(in: context) { for entry in expired { context.delete(entry) } }
    }

    /// Explicitly confirmed reset only. Does not touch exported backups in Files.
    public func eraseRecords(in context: ModelContext) throws {
        try requireClean(context)
        let habits = try context.fetch(FetchDescriptor<HabitRecord>())
        let trackers = try context.fetch(FetchDescriptor<TimeSinceRecord>())
        let completions = try context.fetch(FetchDescriptor<CompletionRecord>())
        let resets = try context.fetch(FetchDescriptor<TimeSinceResetRecord>())
        let bin = try context.fetch(FetchDescriptor<RecentlyDeletedRecord>())
        try commit(in: context) {
            for value in completions { context.delete(value) }
            for value in resets { context.delete(value) }
            for value in habits { context.delete(value) }
            for value in trackers { context.delete(value) }
            for value in bin { context.delete(value) }
        }
    }

    private func selected(_ ids: Set<UUID>, in context: ModelContext) throws -> [RecentlyDeletedRecord] {
        let entries = try context.fetch(FetchDescriptor<RecentlyDeletedRecord>()).filter { ids.contains($0.id) }
        guard entries.count == ids.count else { throw Failure.selectionChanged }
        return entries
    }

    private func checkRoom(in context: ModelContext, now: Date) throws {
        guard now.timeIntervalSince1970.isFinite else { throw Failure.invalid }
        guard try context.fetchCount(FetchDescriptor<RecentlyDeletedRecord>()) < 2_000 else { throw Failure.full }
    }

    private func requireClean(_ context: ModelContext) throws {
        guard !context.hasChanges else { throw Failure.pendingChanges }
    }

    private func commit(in context: ModelContext, _ mutation: () throws -> Void) throws {
        do { try mutation(); try persist(context) }
        catch { context.rollback(); throw error }
    }
}
