import Foundation
import CryptoKit

nonisolated public enum ExternalHabitSource: String, Sendable {
    case streaks = "Streaks"
    case habitify = "Habitify"
    case simpleCSV = "Simple CSV"
}

nonisolated public enum ImportDateOrder: String, CaseIterable, Sendable {
    case automatic, monthFirst, dayFirst
}

/// Only value types cross from file parsing to the main-actor store.
nonisolated public struct ExternalHabitImport: Sendable {
    public let source: ExternalHabitSource
    public let habits: [HabitBackup]
    public let skippedDays: Int
    public let quantityDays: Int
    public let usesNamesAsIdentity: Bool
    public var totalDays: Int { habits.reduce(0) { $0 + $1.completions.count } }
}

nonisolated public enum ExternalImportError: Error, LocalizedError, Equatable, Sendable {
    case invalidFile(String)
    case needsDateOrder
    case row(Int, String)
    case pendingChanges

    public var errorDescription: String? {
        switch self {
        case .invalidFile(let reason): reason
        case .needsDateOrder: "Choose whether this export puts the month or day first."
        case .row(let row, let reason): "Entry \(row): \(reason) Nothing was imported."
        case .pendingChanges: "Finish your current edit, then try importing again."
        }
    }
}

/// Documented daily CSV formats only. Never guess a completion from a quantity,
/// a localized date, an automatic streak score, or an unknown entry type.
nonisolated public enum ExternalHabitCSV {
    public static let maximumBytes = 8 * 1_024 * 1_024
    public static let maximumRows = 50_000

    public static func parse(_ data: Data, calendar: Calendar = .current, now: Date = .now,
                             dateOrder: ImportDateOrder = .automatic) throws -> ExternalHabitImport {
        guard data.count <= maximumBytes else {
            throw ExternalImportError.invalidFile("This export is too large. Choose fewer habits or a shorter date range (up to 8 MB).")
        }
        guard var text = String(data: data, encoding: .utf8) else {
            throw ExternalImportError.invalidFile("Save the export as a UTF-8 CSV file and try again.")
        }
        if text.first == "\u{FEFF}" { text.removeFirst() }
        let rows: [[String]]
        do { rows = try CSVReader.parse(text) }
        catch { throw ExternalImportError.invalidFile("The CSV has an unfinished quoted field. Export a fresh copy and try again.") }
        guard rows.count > 1, rows.count <= maximumRows + 1 else {
            throw ExternalImportError.invalidFile("Choose a CSV with 1–50,000 daily entries.")
        }
        let header = rows[0].map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
        guard Set(header).count == header.count, !header.contains("") else {
            throw ExternalImportError.invalidFile("The CSV needs a unique name for each column.")
        }
        let columns = Dictionary(uniqueKeysWithValues: header.enumerated().map { ($0.element, $0.offset) })
        let source: ExternalHabitSource
        let nameKey: String, dateKey: String, statusKey: String, idKey: String
        if ["title", "entry_type", "entry_date"].allSatisfy({ columns[$0] != nil }) {
            source = .streaks
            (nameKey, dateKey, statusKey, idKey) = ("title", "entry_date", "entry_type", "task_id")
        } else if ["habit", "date", "status", "habit id"].allSatisfy({ columns[$0] != nil }) {
            source = .habitify
            (nameKey, dateKey, statusKey, idKey) = ("habit", "date", "status", "habit id")
        } else if ["habit", "date", "status"].allSatisfy({ columns[$0] != nil }) {
            source = .simpleCSV
            (nameKey, dateKey, statusKey, idKey) = ("habit", "date", "status", "habit_id")
        } else {
            throw ExternalImportError.invalidFile("Choose a Streaks or Habitify daily CSV, or use the simple CSV format shown below. Tendelm backups use Import Data instead.")
        }
        func field(_ row: [String], _ key: String) -> String {
            guard let index = columns[key], row.indices.contains(index) else { return "" }
            return row[index].trimmingCharacters(in: .whitespacesAndNewlines)
        }
        let order = try resolvedOrder(rows.dropFirst().map { field($0, dateKey) }, requested: dateOrder)
        // Export dates name calendar days, not instants. Retain that day in the
        // user's zone without applying the app's late-night rollover a second time.
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = calendar.timeZone
        var habits: [UUID: HabitBackup] = [:]
        var daysByHabit: [UUID: [CompletionBackup]] = [:]
        var latestNameDate: [UUID: Date] = [:]
        var days: [UUID: CompletionBackup] = [:]
        var skipped = 0, quantities = 0
        var usesNames = false
        for (offset, row) in rows.dropFirst().enumerated() {
            let number = offset + 2
            guard row.count == header.count else {
                throw ExternalImportError.row(number, "The number of columns doesn't match the header.")
            }
            let name = field(row, nameKey)
            guard !name.isEmpty, name.count <= 240 else {
                throw ExternalImportError.row(number, "The habit name must contain 1–240 characters.")
            }
            let sourceID = field(row, idKey)
            usesNames = usesNames || sourceID.isEmpty
            let habitID = stableID([source.rawValue, sourceID.isEmpty ? "name" : "id", sourceID.isEmpty ? name : sourceID])
            guard let date = parseDay(field(row, dateKey), order: order, calendar: gregorian) else {
                throw ExternalImportError.row(number, "Use a real date such as 2025-06-15. Ambiguous or timestamp dates need a date-only export.")
            }
            guard date <= gregorian.startOfDay(for: now) else {
                throw ExternalImportError.row(number, "This day is in the future.")
            }
            let status = field(row, statusKey).lowercased()
            let completed: Bool, isSkipped: Bool
            switch (source, status) {
            case (.streaks, "completed_manually"), (.habitify, "completed"), (.simpleCSV, "completed"):
                (completed, isSkipped) = (true, false)
            case (.streaks, "skipped_manually"), (.habitify, "skipped"), (.simpleCSV, "skipped"):
                (completed, isSkipped) = (false, true)
            case (.streaks, "missed_manually"), (.habitify, "failed"), (.simpleCSV, "failed"):
                (completed, isSkipped) = (false, false)
            default:
                throw ExternalImportError.row(number, "This status isn't supported yet: \(String(status.prefix(80))). Choose completed, skipped or failed daily entries.")
            }
            var notes = [field(row, columns["notes"] == nil ? "note" : "notes")].filter { !$0.isEmpty }
            if !completed { notes.append("Imported from \(source.rawValue): \(isSkipped ? "skipped" : "failed").") }
            let quantity = field(row, source == .streaks ? "quantity" : "total log")
            let unit = field(row, "unit")
            if !quantity.isEmpty { notes.append("Original log: \(quantity)\(unit.isEmpty ? "" : " " + unit).") }
            let note = notes.joined(separator: "\n\n")
            guard note.count <= 10_000 else { throw ExternalImportError.row(number, "The note is longer than 10,000 characters.") }
            let parts = gregorian.dateComponents([.year, .month, .day], from: date)
            let dayKey = "\(parts.year!)-\(parts.month!)-\(parts.day!)"
            let completion = CompletionBackup(id: stableID([habitID.uuidString, dayKey]), date: date,
                                              value: completed ? 1 : 0, note: note.isEmpty ? nil : note)
            if let prior = days[completion.id] {
                guard prior == completion else { throw ExternalImportError.row(number, "This habit has conflicting entries on the same day.") }
                continue
            }
            days[completion.id] = completion
            daysByHabit[habitID, default: []].append(completion)
            if isSkipped { skipped += 1 }
            if !quantity.isEmpty { quantities += 1 }
            if var habit = habits[habitID] {
                habit.createdAt = min(habit.createdAt, date)
                if date >= (latestNameDate[habitID] ?? date) { habit.name = name; latestNameDate[habitID] = date }
                habits[habitID] = habit
            } else {
                guard habits.count < 500 else { throw ExternalImportError.invalidFile("Choose up to 500 habits per import.") }
                habits[habitID] = HabitBackup(id: habitID, name: name, frequency: .daily, type: .binary,
                    createdAt: date, color: .green, icon: "circle", remindersEnabled: false,
                    reminderHour: 9, reminderMinute: 0, completions: [])
                latestNameDate[habitID] = date
            }
        }
        var sorted: [HabitBackup] = []
        sorted.reserveCapacity(habits.count)
        for var habit in habits.values {
            var completions: [CompletionBackup] = daysByHabit[habit.id] ?? []
            completions.sort { $0.date < $1.date }
            habit.completions = completions
            sorted.append(habit)
        }
        sorted.sort { left, right in
            if left.name == right.name { return left.id.uuidString < right.id.uuidString }
            return left.name < right.name
        }
        return ExternalHabitImport(source: source, habits: sorted, skippedDays: skipped,
                                   quantityDays: quantities, usesNamesAsIdentity: usesNames)
    }

    private static func resolvedOrder(_ dates: [String], requested: ImportDateOrder) throws -> ImportDateOrder {
        guard requested == .automatic else { return requested }
        var inferred: ImportDateOrder?
        var ambiguous = false
        for date in dates where date.contains("/") {
            let pieces = date.split(separator: "/", omittingEmptySubsequences: false)
            guard pieces.count == 3, pieces[2].count == 4, let a = Int(pieces[0]), let b = Int(pieces[1]) else { continue }
            let hint: ImportDateOrder? = a > 12 ? .dayFirst : b > 12 ? .monthFirst : nil
            ambiguous = ambiguous || (a != b && hint == nil)
            if let hint {
                if let inferred, inferred != hint { throw ExternalImportError.invalidFile("Dates mix month-first and day-first order. Export dates as YYYY-MM-DD.") }
                inferred = hint
            }
        }
        if let inferred { return inferred }
        if ambiguous { throw ExternalImportError.needsDateOrder }
        return .monthFirst // Equal month/day is unambiguous.
    }

    private static func parseDay(_ text: String, order: ImportDateOrder, calendar: Calendar) -> Date? {
        let parts: [Int]
        let tokens: [Substring]
        if text.contains("-") {
            tokens = text.split(separator: "-", omittingEmptySubsequences: false)
            guard tokens.count == 3, tokens[0].count == 4, tokens[1].count == 2, tokens[2].count == 2 else { return nil }
            parts = tokens.compactMap { Int($0) }
        } else if text.contains("/") {
            tokens = text.split(separator: "/", omittingEmptySubsequences: false)
            guard tokens.count == 3, tokens[2].count == 4, let a = Int(tokens[0]), let b = Int(tokens[1]), let y = Int(tokens[2]) else { return nil }
            parts = order == .dayFirst ? [y, b, a] : [y, a, b]
        } else {
            guard text.count == 8, text.allSatisfy({ $0.isASCII && $0.isNumber }) else { return nil }
            parts = [Int(text.prefix(4))!, Int(text.dropFirst(4).prefix(2))!, Int(text.suffix(2))!]
        }
        guard parts.count == 3, (1...9999).contains(parts[0]), (1...12).contains(parts[1]), (1...31).contains(parts[2]) else { return nil }
        let components = DateComponents(year: parts[0], month: parts[1], day: parts[2])
        guard let date = calendar.date(from: components) else { return nil }
        let actual = calendar.dateComponents([.year, .month, .day], from: date)
        guard actual.year == parts[0], actual.month == parts[1], actual.day == parts[2] else { return nil }
        return date
    }

    private static func stableID(_ parts: [String]) -> UUID {
        let input = "com.n3mostudio.tendelm.external.v1:" + parts.map { "\($0.utf8.count):\($0)" }.joined()
        var b = Array(SHA256.hash(data: Data(input.utf8)).prefix(16))
        b[6] = (b[6] & 0x0f) | 0x80 // RFC 9562 custom, version 8.
        b[8] = (b[8] & 0x3f) | 0x80
        return UUID(uuid: (b[0], b[1], b[2], b[3], b[4], b[5], b[6], b[7], b[8], b[9], b[10], b[11], b[12], b[13], b[14], b[15]))
    }
}
