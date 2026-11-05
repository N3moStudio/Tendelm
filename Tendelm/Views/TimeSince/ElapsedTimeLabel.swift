import SwiftUI
import TendelmCore

struct ElapsedTimeLabel: View {
    let start: Date
    var showsSeconds = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        // Timeline invalidates only this label, never queries or the history grid.
        TimelineView(.animation(minimumInterval: showsSeconds ? 1 : 60, paused: scenePhase != .active)) { context in
            let duration = ElapsedDuration(from: start, to: context.date)
            ViewThatFits(in: .horizontal) {
                digits(duration, vertical: false)
                digits(duration, vertical: true)
            }
            .monospacedDigit()
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibleDuration(duration))
        }
    }

    private func digits(_ duration: ElapsedDuration, vertical: Bool) -> some View {
        let layout = vertical ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8)) : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: 12))
        return layout {
            unit(duration.days, label: "days")
            unit(duration.hours, label: "hrs")
            unit(duration.minutes, label: "min")
            if showsSeconds { unit(duration.seconds, label: "sec") }
        }
    }

    private func unit(_ value: Int, label: LocalizedStringKey) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text(value, format: .number)
                .font(.title2.weight(.medium))
                .foregroundStyle(Color.kadoForeground)
            Text(label)
                .font(.caption)
                .foregroundStyle(Color.kadoForegroundSecondary)
        }
        .fixedSize(horizontal: true, vertical: false)
    }

    private func accessibleDuration(_ value: ElapsedDuration) -> String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full
        formatter.allowedUnits = showsSeconds ? [.day, .hour, .minute, .second] : [.day, .hour, .minute]
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: Double(value.totalSeconds)) ?? ""
    }
}
