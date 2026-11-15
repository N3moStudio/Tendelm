import Foundation
import SwiftData

public enum ItemOrdering {
    /// Reorders only the visible slots, preserving hidden / other-section positions.
    public static func replacingSlots(in all: [UUID], with ordered: [UUID]) throws -> [UUID] {
        guard Set(all).count == all.count, Set(ordered).count == ordered.count,
              Set(ordered).isSubset(of: Set(all)) else { throw OrderError.staleItems }
        let selected = Set(ordered)
        var iterator = ordered.makeIterator()
        return all.map { selected.contains($0) ? iterator.next()! : $0 }
    }

    public static func trackers(_ values: [TimeSinceTracker]) -> [TimeSinceTracker] {
        values.sorted {
            if $0.sortOrder != $1.sortOrder { return ($0.sortOrder ?? Int.max) < ($1.sortOrder ?? Int.max) }
            if $0.startedAt != $1.startedAt { return $0.startedAt < $1.startedAt }
            return $0.id.uuidString < $1.id.uuidString
        }
    }

    public enum OrderError: LocalizedError {
        case staleItems
        public var errorDescription: String? { "The list changed. Try moving the item again." }
    }
}

@MainActor
public struct ItemOrderStore {
    public init() {}

    public func habits(_ orderedIDs: [UUID], in context: ModelContext) throws {
        let records = try context.fetch(FetchDescriptor<HabitRecord>())
            .filter { $0.archivedAt == nil }
            .sorted { $0.sortOrder == $1.sortOrder ? $0.id.uuidString < $1.id.uuidString : $0.sortOrder < $1.sortOrder }
        let ids = try ItemOrdering.replacingSlots(in: records.map(\.id), with: orderedIDs)
        let byID = Dictionary(uniqueKeysWithValues: records.map { ($0.id, $0) })
        for (index, id) in ids.enumerated() { byID[id]?.sortOrder = index }
        do { try context.save() } catch { context.rollback(); throw error }
    }

    public func trackers(_ orderedIDs: [UUID], in context: ModelContext) throws {
        let records = try context.fetch(FetchDescriptor<TimeSinceRecord>())
        let current = ItemOrdering.trackers(records.map { $0.snapshot }).map(\.id)
        let ids = try ItemOrdering.replacingSlots(in: current, with: orderedIDs)
        let byID = Dictionary(uniqueKeysWithValues: records.map { ($0.id, $0) })
        for (index, id) in ids.enumerated() { byID[id]?.sortOrder = index }
        do { try context.save() } catch { context.rollback(); throw error }
    }
}
