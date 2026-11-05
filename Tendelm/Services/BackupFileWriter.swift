import Foundation
import TendelmCore

/// Encoding and temporary-file IO happen away from the main actor.
enum BackupFileWriter {
    nonisolated static func write(_ document: BackupDocument, format: BackupFormat, filename: String) throws -> URL {
        try Task.checkCancellation()
        let data: Data
        switch format {
        case .json:
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            data = try encoder.encode(document)
        case .csv:
            data = CSVBackupCoder().encode(document)
        }
        try Task.checkCancellation()
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent(filename)
        try data.write(to: url, options: .atomic)
        return url
    }
}
