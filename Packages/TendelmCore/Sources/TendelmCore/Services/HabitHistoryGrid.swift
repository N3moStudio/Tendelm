import Foundation

public struct HabitHistoryDay: Identifiable, Sendable {
    public var id: Date { date }
    public let date: Date
    public let state: DayCell
    public let isToday: Bool
}

/// Week-major history used by a compact, seven-row contribution grid.
/// Reuses Overview's daily values, including partial and off-schedule days.
public struct HabitHistoryGrid: Sendable {
    public let days: [HabitHistoryDay]
    public let weekCount: Int

    public init(habit: Habit, completions: [Completion], today: Date,
                calendar: Calendar, weekCount: Int = 26) {
        self.weekCount = min(max(1, weekCount), 53)
        let anchor = calendar.startOfDay(for: today)
        let weekdayOffset = (calendar.component(.weekday, from: anchor) - calendar.firstWeekday + 7) % 7
        let first = calendar.date(byAdding: .day, value: -weekdayOffset - (self.weekCount - 1) * 7, to: anchor) ?? anchor
        let dates = (0..<(self.weekCount * 7)).compactMap {
            calendar.date(byAdding: .day, value: $0, to: first).map { calendar.startOfDay(for: $0) }
        }
        let states = OverviewMatrix.compute(
            habits: [habit], completions: completions, days: dates, today: anchor,
            calendar: calendar, frequencyEvaluator: DefaultFrequencyEvaluator(calendar: calendar)
        ).first?.days ?? Array(repeating: .notDue, count: dates.count)
        days = zip(dates, states).map {
            HabitHistoryDay(date: $0.0, state: $0.1, isToday: calendar.isDate($0.0, inSameDayAs: anchor))
        }
    }
}
