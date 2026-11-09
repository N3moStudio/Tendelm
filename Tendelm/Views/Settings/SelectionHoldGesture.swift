import SwiftUI
import UIKit

/// A continuous native long press tracks the finger after recognition, including
/// outside its starting row. A normal drag can still scroll before the hold wins.
struct SelectionHoldGesture: UIGestureRecognizerRepresentable {
    let space: String
    let changed: (UIGestureRecognizer.State, CGPoint) -> Void

    func makeUIGestureRecognizer(context: Context) -> UILongPressGestureRecognizer {
        let gesture = UILongPressGestureRecognizer()
        gesture.minimumPressDuration = 0.35
        gesture.allowableMovement = 12
        gesture.cancelsTouchesInView = true
        return gesture
    }

    func handleUIGestureRecognizerAction(_ recognizer: UILongPressGestureRecognizer, context: Context) {
        changed(recognizer.state, context.converter.location(in: .named(space)))
    }
}
