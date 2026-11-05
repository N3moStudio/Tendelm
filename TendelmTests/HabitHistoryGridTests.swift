import Foundation
import Testing
import TendelmCore

@Suite("Habit card history")
struct HabitHistoryGridTests {
    @Test("A grid has seven cells per week, honors week start, and marks the future")
    func gridShape() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        calendar.firstWeekday = 2
        let today = try #require(calendar.date(from: DateComponents(year: 2026, month: 11, day: 4)))
        let habit = Habit(name: "Read", frequency: .daily, type: .binary, createdAt: today)
        let grid = HabitHistoryGrid(habit: habit, completions: [], today: today, calendar: calendar, weekCount: 26)
        #expect(grid.days.count == 26 * 7)
        #expect(calendar.component(.weekday, from: grid.days[0].date) == 2)
        #expect(grid.days.filter { $0.isToday }.count == 1)
        #expect(grid.days.last?.state == .future)
        #expect(Set(grid.days.map { calendar.startOfDay(for: $0.date) }).count == 182)
    }

    @Test("A counter's partial completion remains distinct from complete")
    func partialProgress() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let today = calendar.startOfDay(for: Date(timeIntervalSince1970: 1_700_000_000))
        let habit = Habit(name: "Water", frequency: .daily, type: .counter(target: 8), createdAt: today)
        let completion = Completion(habitID: habit.id, date: today, value: 4)
        let grid = HabitHistoryGrid(habit: habit, completions: [completion], today: today, calendar: calendar)
        let cell = try #require(grid.days.first { $0.isToday })
        #expect(cell.state == .scored(0.5))
    }
}
