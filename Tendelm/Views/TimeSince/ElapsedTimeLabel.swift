import SwiftUI
import TendelmCore

struct ElapsedTimeLabel: View {
    let start: Date
    var showsSeconds = false
    @Environment(\.scenePhase) private var scenePhase
    @State private var visible = false

    var body: some View {
        // Timeline invalidates only this label, never queries or the history grid.
        Group {
            if visible && scenePhase == .active {
                // Anchor updates to the saved start, so minutes change at their
                // actual boundary even when this screen opens mid-minute.
                TimelineView(.periodic(from: start, by: showsSeconds ? 1 : 60)) { context in
                    durationLabel(at: context.date)
                }
            } else {
                durationLabel(at: .now)
            }
        }
        .onAppear { visible = true }
        .onDisappear { visible = false }
    }

    private func durationLabel(at now: Date) -> some View {
        let duration = ElapsedDuration(from: start, to: now)
        return ViewThatFits(in: .horizontal) {
            digits(duration, vertical: false)
            digits(duration, vertical: true)
        }
        .monospacedDigit()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibleDuration(duration))
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
