import Foundation
import TendelmCore

enum ExternalImportFileReader {
    @concurrent
    nonisolated static func read(_ url: URL) async throws -> Data {
        let access = url.startAccessingSecurityScopedResource()
        defer { if access { url.stopAccessingSecurityScopedResource() } }
        try Task.checkCancellation()
        // Read at most the limit plus one byte, including providers with no size metadata.
        let file = try FileHandle(forReadingFrom: url)
        defer { try? file.close() }
        var data = Data()
        while data.count <= ExternalHabitCSV.maximumBytes {
            try Task.checkCancellation()
            guard let chunk = try file.read(upToCount: min(64 * 1_024, ExternalHabitCSV.maximumBytes + 1 - data.count)),
                  !chunk.isEmpty else { break }
            data.append(chunk)
        }
        guard data.count <= ExternalHabitCSV.maximumBytes else {
            throw ExternalImportError.invalidFile("Choose an export smaller than 8 MB.")
        }
        return data
    }

    @concurrent
    nonisolated static func parse(_ data: Data, dateOrder: ImportDateOrder, calendar: Calendar) async throws -> ExternalHabitImport {
        try Task.checkCancellation()
        let value = try ExternalHabitCSV.parse(data, calendar: calendar, dateOrder: dateOrder)
        try Task.checkCancellation()
        return value
    }
}
