import Foundation
import SwiftData
import Testing
import TendelmCore

@Suite("Saved item ordering") @MainActor
struct ItemOrderingTests {
    private func container(url: URL? = nil) throws -> ModelContainer {
        let schema = Schema(versionedSchema: TendelmSchemaV7.self)
        let config = url.map { ModelConfiguration(schema: schema, url: $0, cloudKitDatabase: .none) }
            ?? ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        return try ModelContainer(for: schema, migrationPlan: TendelmMigrationPlan.self, configurations: config)
            .usingExplicitTestSaves()
    }

    @Test("Moving a section leaves other-section slots intact")
    func sectionSlots() throws {
        let a = UUID(), b = UUID(), c = UUID(), d = UUID()
        #expect(try ItemOrdering.replacingSlots(in: [a, b, c, d], with: [d, b]) == [a, d, c, b])
        #expect(throws: ItemOrdering.OrderError.self) {
            try ItemOrdering.replacingSlots(in: [a, b], with: [b, b])
        }
        #expect(throws: ItemOrdering.OrderError.self) {
            try ItemOrdering.replacingSlots(in: [a, b], with: [c])
        }
    }

    @Test("Tracker order survives edits, resets, JSON and CSV")
    func persistenceAndBackups() throws {
        let db = try container()
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let first = TimeSinceTracker(name: "First", startedAt: start)
        let second = TimeSinceTracker(name: "Second", startedAt: start.addingTimeInterval(60))
        try TimeSinceStore().save(first, in: db.mainContext)
        try TimeSinceStore().save(second, in: db.mainContext)
        try ItemOrderStore().trackers([second.id, first.id], in: db.mainContext)
        var edited = try #require(db.mainContext.fetch(FetchDescriptor<TimeSinceRecord>()).first { $0.id == second.id }?.snapshot)
        edited.name = "Renamed"
        try edited.reset(at: start.addingTimeInterval(120))
        try TimeSinceStore().save(edited, in: db.mainContext)
        let document = try DefaultBackupExporter().export(from: db.mainContext)
        let json = try DefaultBackupImporter().parse(data: DefaultBackupExporter().encode(document))
        let csv = try CSVBackupCoder().decode(CSVBackupCoder().encode(document))
        for decoded in [json, csv] {
            let restored = try container()
            try DefaultBackupImporter().apply(decoded, to: restored.mainContext)
            let values = ItemOrdering.trackers(try ModelContext(restored).fetch(FetchDescriptor<TimeSinceRecord>()).map(\.snapshot))
            #expect(values.map(\.id) == [second.id, first.id])
            #expect(values[0].resets == edited.resets)
            #expect(values[0].name == "Renamed")
        }
    }

    @Test("Legacy tracker JSON decodes without an order field")
    func legacyJSON() throws {
        let tracker = TimeSinceTracker(name: "Legacy")
        let encoded = try JSONEncoder().encode(tracker)
        let decoded = try JSONDecoder().decode(TimeSinceTracker.self, from: encoded)
        #expect(decoded.sortOrder == nil)
        #expect(decoded == tracker)
    }

    @Test("V6 disk migration preserves tracker/reset identity and saves the new order")
    func migrationAndRelaunch() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("order.sqlite")
        let firstID = UUID(), secondID = UUID(), resetID = UUID()
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        do {
            let schema = Schema(versionedSchema: TendelmSchemaV6.self)
            let old = try ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none))
            let first = TendelmSchemaV5.TimeSinceRecord(id: firstID, name: "First", startedAt: start)
            old.mainContext.insert(first)
            old.mainContext.insert(TendelmSchemaV5.TimeSinceRecord(id: secondID, name: "Second", startedAt: start.addingTimeInterval(60)))
            old.mainContext.insert(TendelmSchemaV5.TimeSinceResetRecord(id: resetID, date: start.addingTimeInterval(10), tracker: first))
            try old.mainContext.save()
        }
        do {
            let db = try container(url: url)
            let values = ItemOrdering.trackers(try db.mainContext.fetch(FetchDescriptor<TimeSinceRecord>()).map(\.snapshot))
            #expect(values.map(\.id) == [firstID, secondID])
            #expect(values[0].resets.map(\.id) == [resetID])
            try ItemOrderStore().trackers([secondID, firstID], in: db.mainContext)
        }
        let reopened = try container(url: url)
        let values = ItemOrdering.trackers(try reopened.mainContext.fetch(FetchDescriptor<TimeSinceRecord>()).map(\.snapshot))
        #expect(values.map(\.id) == [secondID, firstID])
        #expect(values[1].resets.map(\.id) == [resetID])
    }
}
