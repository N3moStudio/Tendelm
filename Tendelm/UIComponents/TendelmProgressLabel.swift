import SwiftUI
import ThinkingOrbsKit

/// Only appears while a real export is running. Decorative motion never drives work.
struct TendelmProgressLabel: View {
    let title: LocalizedStringKey
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .body) private var size = 20.0
    @State private var visible = false
    @State private var lowPower = ProcessInfo.processInfo.isLowPowerModeEnabled

    var body: some View {
        HStack(spacing: 8) {
            ThinkingOrb(state: .searching, size: .px20, theme: .auto,
                paused: !visible || scenePhase != .active || reduceMotion || lowPower,
                displaySize: size)
                .accessibilityHidden(true)
            Text(title).fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .onAppear { visible = true; lowPower = ProcessInfo.processInfo.isLowPowerModeEnabled }
        .onDisappear { visible = false }
        .onReceive(NotificationCenter.default.publisher(for: .NSProcessInfoPowerStateDidChange)) { _ in
            lowPower = ProcessInfo.processInfo.isLowPowerModeEnabled
        }
    }
}
