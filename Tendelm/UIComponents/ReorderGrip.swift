import SwiftUI
import TendelmCore

/// A clear drag target outside the row's context-menu region.
/// List owns lifting, edge scrolling, cancellation and settling.
struct ReorderGrip: View {
    let name: String
    let identifier: String
    var moveUp: (() -> Void)?
    var moveDown: (() -> Void)?

    var body: some View {
        Image(systemName: "line.3.horizontal")
            .font(.body.weight(.medium))
            .foregroundStyle(Color.kadoForegroundSecondary)
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
            .accessibilityElement()
            .accessibilityLabel("Reorder \(name)")
            .accessibilityHint("Hold and drag up or down. Or use the Move up and Move down actions.")
            .accessibilityIdentifier(identifier)
            .accessibilityActions {
                if let moveUp { Button("Move up", action: moveUp) }
                if let moveDown { Button("Move down", action: moveDown) }
            }
    }
}
