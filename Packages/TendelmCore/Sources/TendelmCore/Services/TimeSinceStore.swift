import Foundation
import SwiftData

/// Saves before the UI acknowledges a change. A failed save restores the
/// context so a reset cannot appear to have succeeded and vanish on relaunch.
@MainActor
public struct TimeSinceStore {
    public init() {}

    public func save(_ tracker: TimeSinceTracker, in context: ModelContext) throws {
        do {
            try upsert(tracker, in: context)
            try context.save()
        } catch { context.rollback(); throw error }
    }

    /// Stages a validated snapshot so backup import can commit all data atomically.
    public func upsert(_ tracker: TimeSinceTracker, in context: ModelContext) throws {
        try tracker.validate()
        let all = try context.fetch(FetchDescriptor<TimeSinceRecord>())
        let record: TimeSinceRecord
        if let existing = all.first(where: { $0.id == tracker.id }) {
            record = existing
        } else {
            record = TimeSinceRecord(id: tracker.id)
            context.insert(record)
        }
        record.name = tracker.name.trimmingCharacters(in: .whitespacesAndNewlines)
        record.startedAt = tracker.startedAt
        record.color = tracker.color
        let incomingIDs = Set(tracker.resets.map(\.id))
        for event in record.resets ?? [] where !incomingIDs.contains(event.id) {
            context.delete(event)
        }
        let existing = Dictionary((record.resets ?? []).map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        for event in tracker.resets {
            if let saved = existing[event.id] {
                saved.date = event.date
            } else {
                context.insert(TimeSinceResetRecord(id: event.id, date: event.date, tracker: record))
            }
        }
    }

    public func delete(id: UUID, in context: ModelContext) throws {
        let records = try context.fetch(FetchDescriptor<TimeSinceRecord>())
        guard let record = records.first(where: { $0.id == id }) else { return }
        context.delete(record)
        do { try context.save() } catch { context.rollback(); throw error }
    }
}
