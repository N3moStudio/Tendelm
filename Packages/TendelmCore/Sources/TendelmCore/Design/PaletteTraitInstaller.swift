import SwiftUI
import UIKit

/// Install the color trait on this scene's window, not an appearance proxy or
/// process-global palette. Updating the trait redraws colors without rebuilding
/// the navigation hierarchy or replacing the model container.
struct PaletteTraitInstaller: UIViewRepresentable {
    let theme: HabitTheme

    func makeUIView(context: Context) -> PaletteView {
        let view = PaletteView()
        view.isUserInteractionEnabled = false
        view.accessibilityElementsHidden = true
        return view
    }

    func updateUIView(_ view: PaletteView, context: Context) {
        view.theme = theme.current
        view.apply()
    }

    final class PaletteView: UIView {
        var theme: HabitTheme = .kado

        override func didMoveToWindow() {
            super.didMoveToWindow()
            apply()
        }

        func apply() {
            guard let window, window.traitCollection[HabitThemeTrait.self] != theme else { return }
            window.traitOverrides[HabitThemeTrait.self] = theme
        }
    }
}
