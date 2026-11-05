import SwiftUI
import TendelmCore

struct ElapsedTimeLabel: View {
    let start: Date
    var showsSeconds = false
    @Environment(\.scenePhase) private var scenePhase
    @State private var visible = false
    @State private var mountedAt = Date.now

    var body: some View {
        Group {
            if visible && scenePhase == .active {
                let interval: TimeInterval = showsSeconds ? 1 : 60
                // A stable past anchor also ticks before a future start.
                let anchor = start.addingTimeInterval(-max(0, ceil(start.timeIntervalSince(mountedAt) / interval)) * interval)
                TimelineView(.periodic(from: anchor, by: interval)) { context in
                    clockLabel(at: context.date)
                }
            } else {
                clockLabel(at: .now)
            }
        }
        .onAppear { visible = true }
        .onDisappear { visible = false }
    }

    private func clockLabel(at now: Date) -> some View {
        let status = TimeSinceStatus(start: start, now: now)
        return VStack(alignment: .leading, spacing: 6) {
            if status.isScheduled {
                Text("Starts in")
                    .font(.subheadline).foregroundStyle(Color.kadoForegroundSecondary)
                    .accessibilityIdentifier("timeSince.scheduled")
            }
            if status.isScheduled && !showsSeconds && status.duration.totalSeconds < 60 {
                Text("Less than a minute")
                    .font(.title3).foregroundStyle(Color.kadoForeground)
            } else {
                durationLabel(status.duration)
            }
        }
    }

    private func durationLabel(_ duration: ElapsedDuration) -> some View {
        ViewThatFits(in: .horizontal) {
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
