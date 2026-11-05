import Foundation
import Testing
import TendelmCore
@testable import Tendelm

@Suite("Personal backup files")
struct BackupFileWriterTests {
    @Test("Async export produces a readable file containing tracker history", arguments: BackupFormat.allCases)
    func exportedFile(_ format: BackupFormat) async throws {
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        var tracker = TimeSinceTracker(name: "Evening scrolling", startedAt: start)
        try tracker.reset(at: start.addingTimeInterval(600))
        let document = BackupDocument(exportedAt: start, appVersion: "1.0.0", habits: [], timeSinceTrackers: [tracker])
        let url = try await BackupFileWriter.write(document, format: format, filename: "test.\(format.fileExtension)")
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let data = try Data(contentsOf: url)
        let decoded: BackupDocument
        switch format {
        case .json:
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            decoded = try decoder.decode(BackupDocument.self, from: data)
        case .csv:
            decoded = try CSVBackupCoder().decode(data)
        }
        #expect(decoded.timeSinceTrackers == [tracker])
        #expect(decoded.formatVersion == BackupDocument.currentFormatVersion)
    }
}
