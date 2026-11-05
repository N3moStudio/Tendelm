import SwiftUI
import WidgetKit

/// The round Lock Screen "button" for the whole day: a ring that
/// closes as habits get done, with the Tendelm mark in the middle.
/// `LockDayProgressWidget` in the extension wraps it; the app draws
/// it directly for the listing's widget screenshot.
public struct LockDayProgressView: View {
    let entry: SnapshotEntry

    public init(entry: SnapshotEntry) {
        self.entry = entry
    }

    private var progress: DayProgress { entry.snapshot.dayProgress }

    public var body: some View {
        // The capacity style is the one built for "N of M": a thick
        // ring that reads as a fill level. System-drawn, so it already
        // adapts to the lock screen's vibrant and tinted renderings.
        // The count itself is the ring; the centre carries the mark, so
        // the button reads as Tendelm's at a glance. VoiceOver still gets
        // the numbers.
        Gauge(value: progress.fraction) {
            Image(systemName: "checkmark")
        } currentValueLabel: {
            mark
        }
        .gaugeStyle(.accessoryCircularCapacity)
        .widgetAccentable()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    /// A native leaf keeps Tendelm's botanical identity legible in
    /// the Lock Screen's small, monochrome widget surface.
    private var mark: some View {
        Image(systemName: "leaf.fill")
            .resizable()
            .renderingMode(.template)
            .aspectRatio(contentMode: .fit)
            .frame(width: 24, height: 24)
            .foregroundStyle(.primary)
    }

    private var accessibilityLabel: String {
        if progress.total == 0 {
            return String(localized: "No habits due today")
        }
        return String(
            localized: "\(progress.completed) of \(progress.total) habits done today",
            comment: "Medium widget VoiceOver summary. Arg 1 completed, arg 2 total."
        )
    }
}
