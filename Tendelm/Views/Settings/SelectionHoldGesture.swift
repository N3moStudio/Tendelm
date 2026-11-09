import SwiftUI
import UIKit

/// A continuous native long press tracks the finger after recognition, including
/// outside its starting row. A normal drag can still scroll before the hold wins.
struct SelectionHoldGesture: UIGestureRecognizerRepresentable {
    let changed: (UIGestureRecognizer.State, CGPoint) -> Void

    func makeUIGestureRecognizer(context: Context) -> UILongPressGestureRecognizer {
        let gesture = UILongPressGestureRecognizer()
        gesture.minimumPressDuration = 0.35
        gesture.allowableMovement = 12
        gesture.cancelsTouchesInView = true
        gesture.delegate = context.coordinator
        return gesture
    }

    func makeCoordinator(converter: CoordinateSpaceConverter) -> Coordinator { Coordinator() }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                               shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            // Let the hold decide before the row's tap and the List's pan.
            // Moving before 0.35s fails the hold, so ordinary scrolling stays native.
            // Never compete with navigation's edge swipe or another long press.
            !(otherGestureRecognizer is UIScreenEdgePanGestureRecognizer)
                && !(otherGestureRecognizer is UILongPressGestureRecognizer)
        }
    }

    func handleUIGestureRecognizerAction(_ recognizer: UILongPressGestureRecognizer, context: Context) {
        // List cells have separate hosting roots: named converter coordinates
        // can include a different safe-area offset. Both sides use window space.
        changed(recognizer.state, recognizer.location(in: nil))
    }
}
