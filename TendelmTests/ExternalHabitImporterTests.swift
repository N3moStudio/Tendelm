import Foundation
import SwiftData
import Testing
import TendelmCore

@Suite("External habit import persistence") @MainActor
struct ExternalHabitImporterTests {
    private let container: ModelContainer
    private var calendar: Calendar {
        var value = Calendar(identifier: .gregorian)
        value.timeZone = TimeZone(secondsFromGMT: 0)!
        return value
    }
    init() throws {
        container = try ModelContainer(for: HabitRecord.self, CompletionRecord.self,
            TimeSinceRecord.self, TimeSinceResetRecord.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)).usingExplicitTestSaves()
    }
    private func document(_ rows: String) throws -> ExternalHabitImport {
        try ExternalHabitCSV.parse(Data(("Habit,Date,Status,Habit ID\n" + rows).utf8), calendar: calendar)
    }

    @Test("Pasted helper JSON previews without writes and repeat import adds nothing")
    func pastedJSONRoundTrip() throws {
        let text = #"[{"habit":"Read","date":"2025-01-01","status":"completed","habit_id":"read"}]"#
        let document = try ExternalHabitText.parse(ImportTextInput.data(from: [text]), calendar: calendar)
        let context = container.mainContext
        let importer = ExternalHabitImporter()
        #expect(try importer.summary(for: document, in: context, calendar: calendar).newDays == 1)
        #expect(try context.fetchCount(FetchDescriptor<HabitRecord>()) == 0)
        #expect(!context.hasChanges)
        #expect(try importer.apply(document, to: context, calendar: calendar).newDays == 1)
        #expect(try !importer.apply(document, to: context, calendar: calendar).hasAdditions)
        let fresh = ModelContext(container)
        #expect(try fresh.fetchCount(FetchDescriptor<CompletionRecord>()) == 1)
    }

    @Test("Preview is read-only; importing twice adds no duplicate habits or days")
    func repeatedImport() throws {
        let doc = try document("Read,2025-01-01,Completed,a\nRead,2025-01-02,Skipped,a")
        let context = container.mainContext
        let importer = ExternalHabitImporter()
        let preview = try importer.summary(for: doc, in: context, calendar: calendar)
        #expect(preview.newHabits == 1)
        #expect(preview.newDays == 2)
        #expect(try context.fetchCount(FetchDescriptor<HabitRecord>()) == 0)
        #expect(!context.hasChanges)
        #expect(try importer.apply(doc, to: context, calendar: calendar) == preview)
        let again = try importer.apply(doc, to: context, calendar: calendar)
        #expect(!again.hasAdditions)
        #expect(again.existingDays == 2)
        let fresh = ModelContext(container)
        #expect(try fresh.fetchCount(FetchDescriptor<HabitRecord>()) == 1)
        #expect(try fresh.fetchCount(FetchDescriptor<CompletionRecord>()) == 2)
        #expect(try fresh.fetch(FetchDescriptor<CompletionRecord>()).contains { $0.value == 0 && $0.note?.contains("skipped") == true })
    }

    @Test("Later exports preserve edits and unrelated data while adding new days")
    func keepsExistingData() throws {
        let context = container.mainContext
        let unrelated = HabitRecord(name: "Read", frequency: .daily, type: .binary)
        context.insert(unrelated)
        let tracker = TimeSinceTracker(name: "Coffee")
        try TimeSinceStore().save(tracker, in: context)
        let importer = ExternalHabitImporter()
        let doc = try document("Read,2025-01-02,Completed,a")
        try importer.apply(doc, to: context, calendar: calendar)
        let imported = try #require(context.fetch(FetchDescriptor<HabitRecord>()).first { $0.id == doc.habits[0].id })
        imported.name = "My reading"
        imported.color = .purple
        imported.frequency = .daysPerWeek(3)
        imported.remindersEnabled = true
        let originalDay = try #require(imported.completions?.first)
        originalDay.value = 0
        originalDay.note = "My edit"
        try context.save()
        let expanded = try document("Old title,2025-01-02,Completed,a\nOld title,2025-01-03,Completed,a\nOld title,2025-01-01,Completed,a")
        let result = try importer.apply(expanded, to: context, calendar: calendar)
        #expect(result.newDays == 2)
        #expect(result.existingDays == 1)
        #expect(imported.name == "My reading")
        #expect(imported.color == .purple)
        #expect(imported.frequency == .daysPerWeek(3))
        #expect(imported.remindersEnabled)
        #expect(originalDay.note == "My edit")
        #expect(originalDay.value == 0)
        #expect(imported.createdAt == expanded.habits[0].createdAt)
        #expect(unrelated.name == "Read" && (unrelated.completions ?? []).isEmpty)
        #expect(try context.fetch(FetchDescriptor<TimeSinceRecord>()).first?.snapshot == tracker)
    }

    @Test("A manually edited day with a different ID is not duplicated")
    func manualDayConflict() throws {
        let doc = try document("Read,2025-01-01,Completed,a")
        let context = container.mainContext
        let habit = HabitRecord(id: doc.habits[0].id, name: "Read")
        context.insert(habit)
        let manual = CompletionRecord(date: doc.habits[0].completions[0].date.addingTimeInterval(3600),
                                      value: 0, note: "Keep this", habit: habit)
        context.insert(manual)
        try context.save()
        let result = try ExternalHabitImporter().apply(doc, to: context, calendar: calendar)
        #expect(result.newDays == 0)
        #expect(result.existingDays == 1)
        #expect(try context.fetchCount(FetchDescriptor<CompletionRecord>()) == 1)
        #expect(manual.note == "Keep this" && manual.value == 0)
    }

    @Test("Changed goal types fail before any other habit is inserted")
    func changedType() throws {
        let doc = try document("A new habit,2025-01-01,Completed,a\nWalk,2025-01-01,Completed,b")
        let context = container.mainContext
        let id = try #require(doc.habits.first { $0.name == "Walk" }?.id)
        context.insert(HabitRecord(id: id, name: "Walk", type: .counter(target: 10)))
        try context.save()
        #expect(throws: ExternalImportError.self) {
            try ExternalHabitImporter().apply(doc, to: context, calendar: calendar)
        }
        #expect(try context.fetchCount(FetchDescriptor<HabitRecord>()) == 1)
        #expect(try context.fetchCount(FetchDescriptor<CompletionRecord>()) == 0)
        #expect(!context.hasChanges)
    }

    @Test("An unfinished edit is never rolled back by an import")
    func pendingEdit() throws {
        let doc = try document("Read,2025-01-01,Completed,a")
        let context = container.mainContext
        let editing = HabitRecord(name: "Unsaved draft")
        context.insert(editing)
        #expect(throws: ExternalImportError.pendingChanges) {
            try ExternalHabitImporter().apply(doc, to: context, calendar: calendar)
        }
        #expect(context.hasChanges)
        #expect(editing.name == "Unsaved draft")
        #expect(try context.fetchCount(FetchDescriptor<HabitRecord>()) == 1)
    }

    @Test("Changing a goal type still allows a repeated import with no new days")
    func changedTypeRepeat() throws {
        let doc = try document("Read,2025-01-01,Completed,a")
        let context = container.mainContext
        let importer = ExternalHabitImporter()
        try importer.apply(doc, to: context, calendar: calendar)
        let habit = try #require(context.fetch(FetchDescriptor<HabitRecord>()).first)
        habit.type = .counter(target: 10)
        try context.save()
        let result = try importer.apply(doc, to: context, calendar: calendar)
        #expect(!result.hasAdditions)
        #expect(habit.type == .counter(target: 10))
    }

    @Test("A source entry ID owned by another habit rejects the whole import")
    func conflictingIdentity() throws {
        let doc = try document("Read,2025-01-01,Completed,a")
        let context = container.mainContext
        let other = HabitRecord(name: "Unrelated")
        context.insert(other)
        let completion = doc.habits[0].completions[0]
        context.insert(CompletionRecord(id: completion.id, date: completion.date, value: 1, habit: other))
        try context.save()
        #expect(throws: ExternalImportError.self) {
            try ExternalHabitImporter().apply(doc, to: context, calendar: calendar)
        }
        #expect(try context.fetchCount(FetchDescriptor<HabitRecord>()) == 1)
        #expect(try context.fetchCount(FetchDescriptor<CompletionRecord>()) == 1)
    }

    @Test("Imported identity and notes survive a Tendelm backup and restore")
    func backupRoundTrip() throws {
        let doc = try document("Read,2025-01-01,Completed,a\nRead,2025-01-02,Skipped,a")
        try ExternalHabitImporter().apply(doc, to: container.mainContext, calendar: calendar)
        let exporter = DefaultBackupExporter()
        let backup = try exporter.export(from: container.mainContext)
        let restored = try DefaultBackupImporter().parse(data: exporter.encode(backup))
        #expect(restored.habits[0].id == doc.habits[0].id)
        #expect(Set(restored.habits[0].completions) == Set(doc.habits[0].completions))
        let destination = try ModelContainer(for: HabitRecord.self, CompletionRecord.self,
            TimeSinceRecord.self, TimeSinceResetRecord.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)).usingExplicitTestSaves()
        try DefaultBackupImporter().apply(restored, to: destination.mainContext)
        let repeated = try ExternalHabitImporter().apply(doc, to: destination.mainContext, calendar: calendar)
        #expect(!repeated.hasAdditions)
    }
}
