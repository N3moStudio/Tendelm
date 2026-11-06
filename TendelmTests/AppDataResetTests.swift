import Foundation
import SwiftData
import Testing
@testable import Tendelm
import TendelmCore

@Suite("Explicit full reset") @MainActor
struct AppDataResetTests {
    @Test("Reset removes only app preferences")
    func preferences() throws {
        let suite = "reset-test-\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        for key in ["kado.devMode", "personal.appearance", "lastExportAt", "unrelated.setting"] {
            defaults.set("saved", forKey: key)
        }
        AppDataReset.clearPreferences(in: [defaults])
        #expect(defaults.object(forKey: "kado.devMode") == nil)
        #expect(defaults.object(forKey: "personal.appearance") == nil)
        #expect(defaults.object(forKey: "lastExportAt") == nil)
        #expect(defaults.string(forKey: "unrelated.setting") == "saved")
    }

    @Test("Temporary export cleanup keeps unrelated files and empty folders")
    func exports() throws {
        let fm = FileManager.default
        let directory = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let exports = directory.appendingPathComponent(UUID().uuidString)
        let empty = directory.appendingPathComponent(UUID().uuidString)
        try fm.createDirectory(at: exports, withIntermediateDirectories: true)
        try fm.createDirectory(at: empty, withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: directory) }
        let own = exports.appendingPathComponent("tendelm-backup-test.json")
        let other = exports.appendingPathComponent("other.json")
        try Data("own".utf8).write(to: own)
        try Data("other".utf8).write(to: other)
        try AppDataReset.clearTemporaryBackups(in: directory)
        #expect(!fm.fileExists(atPath: own.path))
        #expect(fm.fileExists(atPath: other.path))
        #expect(fm.fileExists(atPath: empty.path))
        try AppDataReset.clearTemporaryBackups(in: directory)
    }

    @Test("Confirmed reset clears both mounted demo and saved production records")
    func bothStores() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let schema = Schema(versionedSchema: TendelmSchemaV6.self)
        let production = try ModelContainer(for: schema, migrationPlan: TendelmMigrationPlan.self,
            configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none))
            .usingExplicitTestSaves()
        let controller = DevModeController(devStoreURL: directory.appendingPathComponent("demo.sqlite"),
            productionContainerFactory: { production })
        production.mainContext.insert(HabitRecord(name: "Saved habit"))
        try production.mainContext.save()
        let demo = controller.container(forDevMode: true)
        #expect(try demo.mainContext.fetchCount(FetchDescriptor<HabitRecord>()) > 0)
        _ = try controller.eraseAllRecords()
        #expect(try production.mainContext.fetchCount(FetchDescriptor<HabitRecord>()) == 0)
        #expect(try demo.mainContext.fetchCount(FetchDescriptor<HabitRecord>()) == 0)
        _ = try controller.eraseAllRecords()
    }
}
