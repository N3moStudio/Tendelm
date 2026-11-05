import Foundation
import SwiftData

nonisolated public struct ExternalImportSummary: Equatable, Sendable {
    public var newHabits = 0
    public var newDays = 0
    public var existingDays = 0
    public var hasAdditions: Bool { newHabits > 0 || newDays > 0 }
}

/// Separate from backup restore: never overwrites an existing daily record,
/// habit name, schedule, appearance, reminder, or any time-since tracker.
@MainActor public struct ExternalHabitImporter {
    public init() {}

    public func summary(for document: ExternalHabitImport, in context: ModelContext,
                        calendar: Calendar = .current) throws -> ExternalImportSummary {
        try plan(document, in: context, calendar: calendar).summary
    }

    @discardableResult
    public func apply(_ document: ExternalHabitImport, to context: ModelContext,
                      calendar: Calendar = .current) throws -> ExternalImportSummary {
        // Rollback must never discard another screen's unfinished changes.
        guard !context.hasChanges else { throw ExternalImportError.pendingChanges }
        let pending = try plan(document, in: context, calendar: calendar)
        guard pending.summary.hasAdditions else { return pending.summary }
        let previousAutosave = context.autosaveEnabled
        context.autosaveEnabled = false
        defer { context.autosaveEnabled = previousAutosave }
        do {
            for item in pending.items {
                let record: HabitRecord
                if let existing = item.existing {
                    record = existing
                } else {
                    record = HabitRecord(id: item.habit.id, name: item.habit.name,
                                         frequency: .daily, type: .binary, createdAt: item.habit.createdAt,
                                         color: .green, icon: "circle", remindersEnabled: false,
                                         sortOrder: item.sortOrder)
                    context.insert(record)
                }
                for day in item.days {
                    context.insert(CompletionRecord(id: day.id, date: day.date, value: day.value,
                                                    note: day.note, habit: record))
                    // Make earlier, newly imported history visible in calculations.
                    record.createdAt = min(record.createdAt, day.date)
                }
            }
            try context.save()
            return pending.summary
        } catch { context.rollback(); throw error }
    }

    private struct Item {
        let habit: HabitBackup
        let existing: HabitRecord?
        let days: [CompletionBackup]
        let sortOrder: Int
    }

    private func plan(_ document: ExternalHabitImport, in context: ModelContext,
                      calendar: Calendar) throws -> (items: [Item], summary: ExternalImportSummary) {
        let records = try context.fetch(FetchDescriptor<HabitRecord>())
        var byID: [UUID: HabitRecord] = [:]
        for record in records {
            guard byID[record.id] == nil else {
                throw ExternalImportError.invalidFile("The library has duplicate habit identities. Resolve them before importing.")
            }
            byID[record.id] = record
        }
        let allDayIDs = Set(try context.fetch(FetchDescriptor<CompletionRecord>()).map(\.id))
        var summary = ExternalImportSummary()
        var items: [Item] = []
        var order = (records.map(\.sortOrder).max() ?? -1) + 1
        for habit in document.habits {
            let existing = byID[habit.id]
            let completions = existing?.completions ?? []
            let ownIDs = Set(completions.map(\.id))
            let occupiedDays = Set(completions.map { calendar.startOfDay(for: $0.date) })
            var additions: [CompletionBackup] = []
            for day in habit.completions {
                if allDayIDs.contains(day.id) && !ownIDs.contains(day.id) {
                    throw ExternalImportError.invalidFile("An entry belongs to a different habit. Nothing was imported.")
                } else if ownIDs.contains(day.id) || occupiedDays.contains(calendar.startOfDay(for: day.date)) {
                    summary.existingDays += 1
                } else {
                    additions.append(day)
                }
            }
            if let existing, existing.type != .binary, !additions.isEmpty {
                throw ExternalImportError.invalidFile("\(existing.name) now uses a different goal type. Leave it out of this export to import the other habits without changing its goals.")
            }
            if existing == nil { summary.newHabits += 1 }
            summary.newDays += additions.count
            items.append(Item(habit: habit, existing: existing, days: additions, sortOrder: order))
            order += 1
        }
        return (items, summary)
    }
}
