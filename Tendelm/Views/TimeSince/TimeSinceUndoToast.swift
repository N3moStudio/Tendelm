import SwiftUI
import TendelmCore

private struct TimeSinceUndoToast: ViewModifier {
    @Binding var action: TimeSinceUndoAction?
    let undo: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

    func body(content: Content) -> some View {
        content
            .safeAreaInset(edge: .bottom, alignment: .trailing, spacing: 0) {
                if let action {
                    Button(action: undo) {
                        Label("Undo", systemImage: "arrow.uturn.backward")
                            .foregroundStyle(Color.kadoBackground)
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 6)
                            .frame(minHeight: 32)
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.capsule)
                    .tint(Color.kadoAccent)
                    .accessibilityLabel(undoLabel(action))
                    .accessibilityHint("Reverses only your most recent change.")
                    .accessibilityIdentifier("timeSince.undo")
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                    .transition(.opacity)
                }
            }
            .animation(reduceMotion ? nil : .easeOut(duration: 0.18), value: action?.id)
            .task(id: action?.id) {
                guard let pending = action else { return }
                do { try await ContinuousClock().sleep(until: pending.deadline) }
                catch { return }
                guard !Task.isCancelled, action?.id == pending.id else { return }
                action = nil
            }
            .onDisappear { action = nil }
            .onChange(of: scenePhase) { _, phase in
                if phase != .active { action = nil }
            }
    }

    private func undoLabel(_ action: TimeSinceUndoAction) -> LocalizedStringKey {
        switch action.change {
        case .added: "Undo reset"
        case .deleted: "Undo history deletion"
        }
    }
}

extension View {
    func timeSinceUndo(_ action: Binding<TimeSinceUndoAction?>, perform undo: @escaping () -> Void) -> some View {
        modifier(TimeSinceUndoToast(action: action, undo: undo))
    }
}
