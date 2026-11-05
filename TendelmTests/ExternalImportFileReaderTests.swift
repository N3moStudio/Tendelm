import Foundation
import Testing
import TendelmCore
@testable import Tendelm

@Suite("External import file reading")
struct ExternalImportFileReaderTests {
    @Test("A local file is read and parsed using the production path")
    func readAndParse() async throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".csv")
        defer { try? FileManager.default.removeItem(at: url) }
        let data = Data("habit,date,status\nRead,2025-01-01,completed".utf8)
        try data.write(to: url)
        let read = try await ExternalImportFileReader.read(url)
        #expect(read == data)
        let document = try await ExternalImportFileReader.parse(read, dateOrder: .automatic, calendar: .current)
        #expect(document.totalDays == 1)
    }

    @Test("Oversized files are stopped by the reader")
    func oversized() async throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".csv")
        defer { try? FileManager.default.removeItem(at: url) }
        try Data(repeating: 65, count: ExternalHabitCSV.maximumBytes + 1).write(to: url)
        await #expect(throws: ExternalImportError.self) { try await ExternalImportFileReader.read(url) }
    }
}
