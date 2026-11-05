import SwiftUI

/// Controls change once at the scheduled start. Frequent clock redraws stay
/// inside ElapsedTimeLabel, away from navigation and the surrounding layout.
struct TimeSinceStartGate<Content: View>: View {
    let start: Date
    @ViewBuilder var content: (Date) -> Content
    @Environment(\.scenePhase) private var scenePhase
    @State private var now = Date.now

    var body: some View {
        content(now)
            .task(id: WakeKey(start: start, phase: scenePhase)) {
                now = .now
                guard scenePhase == .active else { return }
                do {
                    while now < start {
                        // Bound very distant dates; cancellation on disappearance
                        // or backgrounding stops this task without background work.
                        try await Task.sleep(for: .seconds(min(start.timeIntervalSince(now), 3_600)))
                        try Task.checkCancellation()
                        now = .now
                    }
                } catch {
                    // SwiftUI cancels this wait when the view leaves or changes.
                }
            }
    }

    private struct WakeKey: Equatable {
        let start: Date
        let phase: ScenePhase
    }
}
