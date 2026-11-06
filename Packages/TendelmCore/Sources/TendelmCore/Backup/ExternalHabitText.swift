import Foundation
import CoreFoundation

/// Accept raw CSV or the array of row objects produced by a CSV-to-JSON helper.
/// Both paths use the same daily-field validation, date handling and identities.
nonisolated public enum ExternalHabitText {
    public static func parse(_ data: Data, calendar: Calendar = .current, now: Date = .now,
                             dateOrder: ImportDateOrder = .automatic) throws -> ExternalHabitImport {
        guard data.count <= ExternalHabitCSV.maximumBytes else {
            throw ExternalImportError.invalidFile("Choose an export smaller than 8 MB.")
        }
        let text = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines.union(CharacterSet(charactersIn: "\u{FEFF}")))
        guard text?.first == "[" || text?.first == "{" else {
            return try ExternalHabitCSV.parse(data, calendar: calendar, now: now, dateOrder: dateOrder)
        }
        let object: Any
        do { object = try JSONSerialization.jsonObject(with: Data((text ?? "").utf8)) }
        catch { throw ExternalImportError.invalidFile("The JSON is incomplete. Copy all of the helper's JSON output and try again.") }
        guard let rows = object as? [[String: Any]], !rows.isEmpty,
              rows.count <= ExternalHabitCSV.maximumRows else {
            throw ExternalImportError.invalidFile("Use a JSON array of daily CSV rows. Tendelm JSON backups belong in Import Data.")
        }
        let headers = Array(Set(rows.flatMap { $0.keys })).sorted()
        guard !headers.isEmpty, headers.count <= 100 else {
            throw ExternalImportError.invalidFile("This export has too many columns or no daily fields.")
        }
        var csv = CSVWriter.write([headers])
        var byteCount = csv.utf8.count
        for row in rows {
            try Task.checkCancellation()
            let fields = try headers.map { key -> String in
                guard let value = row[key] else { return "" }
                if let value = value as? String { return value }
                if value is NSNull { return "null" }
                if let number = value as? NSNumber {
                    if CFGetTypeID(number) == CFBooleanGetTypeID() { return number.boolValue ? "true" : "false" }
                    guard number.doubleValue.isFinite else { throw invalidCell() }
                    return number.stringValue
                }
                throw invalidCell()
            }
            let line = CSVWriter.write([fields])
            byteCount += line.utf8.count
            guard byteCount <= ExternalHabitCSV.maximumBytes else {
                throw ExternalImportError.invalidFile("The converted export is too large. Choose fewer days or habits.")
            }
            csv += line
        }
        return try ExternalHabitCSV.parse(Data(csv.utf8), calendar: calendar, now: now, dateOrder: dateOrder)
    }

    private static func invalidCell() -> ExternalImportError {
        .invalidFile("A daily field contains nested JSON. Turn off Parse JSON in the helper, then copy its output again.")
    }
}
