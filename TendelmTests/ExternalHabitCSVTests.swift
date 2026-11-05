import Foundation
import Testing
import TendelmCore

@Suite("External habit CSV")
struct ExternalHabitCSVTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }
    private func parse(_ text: String, order: ImportDateOrder = .automatic) throws -> ExternalHabitImport {
        try ExternalHabitCSV.parse(Data(text.utf8), calendar: calendar,
                                   now: Date(timeIntervalSince1970: 1_800_000_000), dateOrder: order)
    }

    @Test("Streaks documented columns preserve quoted notes and explicit status")
    func streaks() throws {
        let doc = try parse("""
        task_id,title,icon,entry_type,entry_date,entry_timestamp_local,entry_timezone,quantity,page,notes
        a,"Read, slowly",,completed_manually,20250101,,,2,,"First line
        Second, \"\"quoted\"\" 🌿"
        a,"Read, slowly",,skipped_manually,20250102,,,,,
        a,"Read, slowly",,missed_manually,20250103,,,,,
        """)
        #expect(doc.source == .streaks)
        #expect(doc.habits.count == 1)
        #expect(doc.habits[0].name == "Read, slowly")
        #expect(doc.habits[0].completions.map(\.value) == [1, 0, 0])
        #expect(doc.habits[0].completions[0].note?.contains("Second, \"quoted\" 🌿") == true)
        #expect(doc.habits[0].completions[0].note?.contains("Original log: 2") == true)
        #expect(doc.habits[0].completions[1].note?.contains("skipped") == true)
        #expect(doc.skippedDays == 1)
        #expect(doc.quantityDays == 1)
        #expect(!doc.usesNamesAsIdentity)
    }

    @Test("Habitify uses completion status, not the quantity, and retains units")
    func habitify() throws {
        let doc = try parse("Habit,Date,Total log,Unit,Status,Habit ID\nWalk,2025-01-01,4,km,Failed,h1\nWalk,2025-01-02,0,km,Completed,h1")
        #expect(doc.source == .habitify)
        #expect(doc.habits[0].completions.map(\.value) == [0, 1])
        #expect(doc.habits[0].completions[0].note?.contains("4 km") == true)
    }

    @Test("IDs survive reordered exports and renames when the source includes an ID")
    func stableIdentity() throws {
        let a = try parse("Habit,Date,Status,Habit ID\nRead,2025-01-01,Completed,1\nWalk,2025-01-02,Completed,2")
        let b = try parse("Habit,Date,Status,Habit ID\nWalk,2025-01-02,Completed,2\nRead more,2025-01-01,Completed,1")
        #expect(a.habits[0].id == b.habits[0].id)
        #expect(a.habits[0].completions[0].id == b.habits[0].completions[0].id)
        let otherSource = try parse("task_id,title,entry_type,entry_date\n1,Read,completed_manually,20250101")
        #expect(a.habits[0].id != otherSource.habits[0].id)
    }

    @Test("Identical rows deduplicate; conflicting rows reject the entire file")
    func duplicates() throws {
        let row = "Read,2025-01-01,completed"
        let doc = try parse("habit,date,status\n\(row)\n\(row)")
        #expect(doc.totalDays == 1)
        #expect(throws: ExternalImportError.self) {
            try parse("habit,date,status\n\(row)\nRead,2025-01-01,failed")
        }
    }

    @Test("Equal names with distinct source IDs remain distinct habits")
    func identicalNames() throws {
        let doc = try parse("Habit,Date,Status,Habit ID\nRead,2025-01-01,Completed,1\nRead,2025-01-01,Completed,2")
        #expect(doc.habits.count == 2)
        #expect(doc.habits[0].id != doc.habits[1].id)
    }

    @Test("Ambiguous dates require a choice and respect both orders")
    func ambiguousDates() throws {
        let text = "Habit,Date,Status,Habit ID\nRead,06/07/2025,Completed,1"
        #expect(throws: ExternalImportError.needsDateOrder) { try parse(text) }
        let monthFirst = try parse(text, order: .monthFirst).habits[0].completions[0].date
        let dayFirst = try parse(text, order: .dayFirst).habits[0].completions[0].date
        #expect(calendar.component(.month, from: monthFirst) == 6)
        #expect(calendar.component(.day, from: monthFirst) == 7)
        #expect(calendar.component(.month, from: dayFirst) == 7)
        #expect(calendar.component(.day, from: dayFirst) == 6)
    }

    @Test("Unambiguous dates determine the whole file's date order")
    func inferDateOrder() throws {
        let doc = try parse("habit,date,status\nRead,06/07/2025,completed\nRead,15/07/2025,completed")
        #expect(doc.habits[0].completions.allSatisfy { calendar.component(.month, from: $0.date) == 7 })
        #expect(throws: ExternalImportError.self) {
            try parse("habit,date,status\nRead,06/15/2025,completed\nRead,15/07/2025,completed")
        }
    }

    @Test("Invalid, future, timestamp dates and unsupported statuses never become checkmarks",
          arguments: ["2025-02-29,completed", "2025-13-01,completed", "2030-01-01,completed",
                      "2025-01-01T23:00:00Z,completed", "2025-01-01,partial", "2025-01-01,2"])
    func rejectsBadEntries(_ fields: String) {
        #expect(throws: ExternalImportError.self) { try parse("habit,date,status\nRead,\(fields)") }
    }

    @Test("Local export days stay on their named day across daylight saving")
    func daylightSaving() throws {
        var local = calendar
        local.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        let doc = try ExternalHabitCSV.parse(Data("habit,date,status\nRead,2025-03-09,completed\nRead,2025-03-10,completed".utf8), calendar: local)
        let dates = doc.habits[0].completions.map(\.date)
        #expect(dates.map { local.component(.day, from: $0) } == [9, 10])
        #expect(dates[1].timeIntervalSince(dates[0]) == 23 * 3600)
        let shifted = DayBoundary(calendar: local, startHour: 4)
        // Import is already a named day; do not feed it through loggingInstant.
        #expect(dates[0] == local.startOfDay(for: dates[0]))
        #expect(shifted.startOfDay(for: dates[0]) != dates[0])
    }

    @Test("UTF-8 BOM, CRLF and optional notes work in simple CSV")
    func simpleFormat() throws {
        let doc = try parse("\u{FEFF}habit,date,status,note\r\nRead,2025-01-01,completed,🌿\r\n")
        #expect(doc.source == .simpleCSV)
        #expect(doc.usesNamesAsIdentity)
        #expect(doc.habits[0].completions[0].note == "🌿")
    }

    @Test("Wrong headers, malformed quotes and wrong row lengths reject the file",
          arguments: ["name,day\nRead,2025-01-01", "habit,date,status,status\nRead,2025-01-01,completed,failed",
                      "habit,date,status\n\"Read,2025-01-01,completed", "habit,date,status\nRead,2025-01-01"])
    func malformed(_ text: String) {
        #expect(throws: ExternalImportError.self) { try parse(text) }
    }

    @Test("Oversized files fail before parsing")
    func sizeLimit() {
        #expect(throws: ExternalImportError.self) {
            try ExternalHabitCSV.parse(Data(repeating: 65, count: ExternalHabitCSV.maximumBytes + 1))
        }
    }
}
