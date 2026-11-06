import Foundation
import Testing
import TendelmCore

@Suite("Pasted imports")
struct ImportTextTests {
    @Test("Pasted text preserves Unicode, newlines and the original contents")
    func preservesText() throws {
        let text = "\u{FEFF}habit,date,status,note\nRead,2025-01-01,completed,🌿 café\n"
        #expect(try ImportTextInput.data(from: [text]) == Data(text.utf8))
    }

    @Test("Empty, multiple, oversized and link-only clipboard inputs are rejected")
    func rejectsInvalidClipboard() {
        for values in [[], ["   \n"], ["a", "b"], ["https://example.com/backup.json"], ["file:///backup.json"]] {
            #expect(throws: ExternalImportError.self) { try ImportTextInput.data(from: values) }
        }
        #expect(throws: ExternalImportError.self) {
            try ImportTextInput.data(from: ["🌿🌿"], maximumBytes: 7)
        }
    }

    @Test("CSV helper JSON has the same identities and history as the original CSV")
    func convertedJSONMatchesCSV() throws {
        let note = "Five pages, \"quietly\"\n🌿 café"
        let rows = [["Habit": "Read", "Date": "2025-01-01", "Status": "Completed", "Habit ID": "00721", "Note": note],
                    ["Habit": "Read", "Date": "2025-01-02", "Status": "Skipped", "Habit ID": "00721", "Note": ""]]
        let json = try JSONSerialization.data(withJSONObject: rows)
        let csv = CSVWriter.write([["Habit", "Date", "Status", "Habit ID", "Note"],
                                   ["Read", "2025-01-01", "Completed", "00721", note],
                                   ["Read", "2025-01-02", "Skipped", "00721", ""]])
        let fromCSV = try ExternalHabitText.parse(Data(csv.utf8))
        let fromJSON = try ExternalHabitText.parse(json)
        #expect(fromJSON.source == .habitify)
        #expect(fromJSON.habits == fromCSV.habits)
        #expect(fromJSON.skippedDays == fromCSV.skippedDays)
    }

    @Test("Converted numbers and boolean text retain their CSV meaning")
    func scalarValues() throws {
        let json = Data(#"[{"habit":"Read","date":"2025-01-01","status":"completed","habit_id":42,"note":false}]"#.utf8)
        let csv = Data("habit,date,status,habit_id,note\nRead,2025-01-01,completed,42,false".utf8)
        #expect(try ExternalHabitText.parse(json).habits == ExternalHabitText.parse(csv).habits)
    }

    @Test("Unordered JSON keys and absent optional columns preserve every daily row")
    func optionalColumns() throws {
        let json = Data(#"[{"habit":"Read","date":"2025-01-01","status":"completed"},{"status":"failed","date":"2025-01-02","habit":"Read","note":"Later"}]"#.utf8)
        let result = try ExternalHabitText.parse(json)
        #expect(result.habits.count == 1)
        #expect(result.totalDays == 2)
        #expect(result.habits[0].completions.contains { $0.note?.contains("Later") == true })
    }

    @Test("Ambiguous dates still require a choice after JSON conversion")
    func dateOrder() throws {
        let json = Data(#"[{"habit":"Read","date":"01/02/2025","status":"completed"}]"#.utf8)
        #expect(throws: ExternalImportError.needsDateOrder) { try ExternalHabitText.parse(json) }
        #expect(try ExternalHabitText.parse(json, dateOrder: .dayFirst).totalDays == 1)
    }

    @Test("Malformed, nested, duplicate-column and non-daily JSON cannot be imported",
          arguments: ["[", "[]", "{}", "[1]", #"[{"habit":{}}]"#,
                      #"[{"Habit":"Read","habit":"Other","date":"2025-01-01","status":"completed"}]"#,
                      #"{"formatVersion":2,"habits":[]}"#])
    func rejectsOtherJSON(_ text: String) {
        #expect(throws: ExternalImportError.self) { try ExternalHabitText.parse(Data(text.utf8)) }
    }
}
