import SwiftUI
import TendelmCore

/// A glanceable history, not 182 tiny tap targets. The card opens the existing
/// accessible calendar editor. The header already describes the habit, so
/// the decorative grid must not override its navigation label or action.
struct HabitHistoryCardGrid: View {
    let habit: Habit
    let completions: [Completion]
    @Environment(\.calendar) private var calendar
    @Environment(\.today) private var today
    @Environment(\.habitTheme) private var theme
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var availableWidth: CGFloat = 300

    var body: some View {
        let weeks = typeSize.isAccessibilitySize ? 13 : 26
        let grid = HabitHistoryGrid(habit: habit, completions: completions, today: today, calendar: calendar, weekCount: weeks)
        GeometryReader { geometry in
            let gap: CGFloat = 2
            let labelWidth: CGFloat = 22
            let cell = min(14, max(4, (geometry.size.width - labelWidth - CGFloat(weeks - 1) * gap) / CGFloat(weeks)))
            HStack(alignment: .bottom, spacing: 5) {
                VStack(spacing: gap) {
                    ForEach(0..<7, id: \.self) { day in
                        Text(day == 1 || day == 3 || day == 5 ? weekday(day) : "")
                            .font(.caption2)
                            .foregroundStyle(Color.kadoForegroundSecondary)
                            .frame(width: labelWidth - 5, height: cell)
                    }
                }
                HStack(alignment: .bottom, spacing: gap) {
                    ForEach(0..<weeks, id: \.self) { week in
                        VStack(alignment: .leading, spacing: 5) {
                            Text(monthLabel(week, days: grid.days))
                                .font(.caption2)
                                .foregroundStyle(Color.kadoForegroundSecondary)
                                .fixedSize()
                                .frame(width: cell, height: 16, alignment: .leading)
                            VStack(spacing: gap) {
                                ForEach(Array(grid.days[(week * 7)..<(week * 7 + 7)])) { day in
                                    RoundedRectangle(cornerRadius: 1.5)
                                        .fill(fill(for: day.state))
                                        .overlay {
                                            if day.isToday {
                                                RoundedRectangle(cornerRadius: 1.5)
                                                    .stroke(Color.kadoForegroundSecondary, lineWidth: 1)
                                            } else if case .offSchedule = day.state {
                                                RoundedRectangle(cornerRadius: 1.5)
                                                    .stroke(habit.color.color(in: theme), lineWidth: 0.7)
                                            }
                                        }
                                        .frame(width: cell, height: cell)
                                }
                            }
                        }
                    }
                }
            }
        }
        .frame(height: min(14, max(4, (availableWidth - 22 - CGFloat(weeks - 1) * 2) / CGFloat(weeks))) * 7 + 33)
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { availableWidth = $0 }
        .dynamicTypeSize(.medium)
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }

    private func weekday(_ index: Int) -> String {
        calendar.veryShortStandaloneWeekdaySymbols[(calendar.firstWeekday - 1 + index) % 7]
    }

    private func monthLabel(_ week: Int, days: [HabitHistoryDay]) -> String {
        let date = days[week * 7].date
        guard week < days.count / 7 - 2 else { return "" }
        if week == 0 || calendar.component(.month, from: days[(week - 1) * 7].date) != calendar.component(.month, from: date) {
            return date.formatted(.dateTime.month(.abbreviated))
        }
        return ""
    }

    private func fill(for state: DayCell) -> Color {
        switch state {
        case .future: return .clear
        case .beforeStart, .notDue: return habit.color.tint(.mark, in: theme).opacity(0.6)
        case .scored(let value), .offSchedule(let value):
            if value >= 1 { return habit.color.color(in: theme) }
            return habit.color.tint(value > 0 ? .tilePartial : .tileLight, in: theme)
        }
    }
}

#Preview("Dark") {
    HabitHistoryCardGrid(habit: Habit(name: "Read", frequency: .daily, type: .binary, createdAt: .now), completions: [])
        .padding().background(Color.kadoBackgroundSecondary).preferredColorScheme(.dark)
}
