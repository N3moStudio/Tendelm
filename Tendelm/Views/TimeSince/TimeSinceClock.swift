import SwiftUI

/// Only visible tracker content ticks. Align the schedule before now, including
/// for future starts, so it ticks during the countdown and at the start itself.
struct TimeSinceClock<Content: View>: View {
    let start: Date
    var showsSeconds = false
    @ViewBuilder var content: (Date) -> Content
    @Environment(\.scenePhase) private var scenePhase
    @State private var visible = false

    var body: some View {
        Group {
            if visible && scenePhase == .active {
                let interval: TimeInterval = showsSeconds ? 1 : 60
                let anchor = start.addingTimeInterval(floor(Date.now.timeIntervalSince(start) / interval) * interval)
                TimelineView(.periodic(from: anchor, by: interval)) { context in
                    content(context.date)
                }
            } else {
                content(.now)
            }
        }
        .onAppear { visible = true }
        .onDisappear { visible = false }
    }
}
