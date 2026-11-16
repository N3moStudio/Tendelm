import SwiftUI
import UIKit

/// A short hold on the dedicated handle wins before the row's context menu.
/// The lifted snapshot follows the finger; storage changes only on a valid release.
struct ReorderDragSource: UIViewRepresentable {
    let id: UUID
    let session: ReorderSession
    let begin: () -> Void
    let commit: ([UUID]) -> Bool

    final class HandleView: UIView {
        var attach: ((HandleView) -> Void)?
        override func didMoveToWindow() { super.didMoveToWindow(); attach?(self) }
        override func layoutSubviews() { super.layoutSubviews(); attach?(self) }
        var cell: UIView? {
            var ancestor = superview
            while let view = ancestor {
                if view is UICollectionViewCell || view is UITableViewCell { return view }
                ancestor = view.superview
            }
            return nil
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }
    func makeUIView(context: Context) -> HandleView {
        let view = HandleView()
        view.backgroundColor = .clear
        view.isAccessibilityElement = false
        let hold = UILongPressGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.changed(_:)))
        hold.minimumPressDuration = 0.25
        hold.allowableMovement = 12
        hold.delegate = context.coordinator
        context.coordinator.hold = hold
        context.coordinator.view = view
        view.attach = { [weak coordinator = context.coordinator] handle in coordinator?.attach(to: handle) }
        session.handles[id] = WeakReorderHandle(view)
        return view
    }
    func updateUIView(_ view: HandleView, context: Context) {
        context.coordinator.source = self
        context.coordinator.attach(to: view)
        session.handles[id] = WeakReorderHandle(view)
        if session.activeID == nil { context.coordinator.finishVisual(cancelled: true) }
    }
    static func dismantleUIView(_ view: HandleView, coordinator: Coordinator) {
        coordinator.finishVisual(cancelled: true)
        if let hold = coordinator.hold { hold.view?.removeGestureRecognizer(hold) }
        view.attach = nil
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var source: ReorderDragSource
        weak var view: HandleView?
        weak var scroll: UIScrollView?
        var hold: UILongPressGestureRecognizer?
        var lifted: UIView?
        var finger = CGPoint.zero
        var offset = CGPoint.zero
        var displayLink: CADisplayLink?
        init(_ source: ReorderDragSource) { self.source = source }

        func attach(to handle: HandleView) {
            guard let host = handle.cell, let hold, hold.view !== host else { return }
            hold.view?.removeGestureRecognizer(hold)
            host.addGestureRecognizer(hold)
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
            guard let view else { return false }
            return view.bounds.contains(touch.location(in: view))
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool { true }

        @objc func changed(_ hold: UILongPressGestureRecognizer) {
            guard let view, let window = view.window else { finishVisual(cancelled: true); return }
            finger = hold.location(in: window)
            switch hold.state {
            case .began:
                source.begin()
                guard source.session.activeID == source.id, let cell = view.cell,
                      let snapshot = cell.snapshotView(afterScreenUpdates: false) else { source.session.cancel(); return }
                let frame = cell.convert(cell.bounds, to: window)
                snapshot.frame = frame
                offset = CGPoint(x: frame.midX - finger.x, y: frame.midY - finger.y)
                snapshot.isUserInteractionEnabled = false
                snapshot.layer.cornerRadius = 18
                snapshot.layer.shadowColor = UIColor.black.cgColor
                snapshot.layer.shadowOpacity = 0.12
                snapshot.layer.shadowRadius = 12
                snapshot.layer.shadowOffset = CGSize(width: 0, height: 4)
                window.addSubview(snapshot)
                lifted = snapshot
                var ancestor = cell.superview
                while let candidate = ancestor {
                    if let list = candidate as? UIScrollView { scroll = list; break }
                    ancestor = candidate.superview
                }
                if !source.session.reduceMotion {
                    UIView.animate(withDuration: 0.18) { snapshot.transform = CGAffineTransform(scaleX: 1.015, y: 1.015) }
                }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                let link = CADisplayLink(target: self, selector: #selector(tick(_:)))
                link.add(to: .main, forMode: .common)
                displayLink = link
            case .changed:
                movePreview()
            case .ended:
                let valid = target(at: finger) != nil
                finishVisual(cancelled: !valid)
                if valid { _ = source.session.drop(commit: source.commit) }
                else { source.session.cancel() }
            case .cancelled, .failed:
                finishVisual(cancelled: true)
                source.session.cancel()
            default: break
            }
        }

        private func target(at point: CGPoint) -> UUID? {
            guard let window = view?.window else { return nil }
            return source.session.original.first { id in
                guard let handle = source.session.handles[id]?.view, handle.window === window,
                      let cell = handle.cell else { return false }
                return cell.convert(cell.bounds, to: window).contains(point)
            }
        }
        private func movePreview() {
            lifted?.center = CGPoint(x: finger.x + offset.x, y: finger.y + offset.y)
            if let target = target(at: finger) { source.session.hover(over: target) }
        }
        @objc private func tick(_ link: CADisplayLink) {
            guard source.session.activeID == source.id else { finishVisual(cancelled: true); return }
            guard let scroll, let window = view?.window else { return }
            let frame = scroll.convert(scroll.bounds, to: window).inset(by: scroll.adjustedContentInset)
            let edge: CGFloat = 56
            let speed: CGFloat
            if finger.y < frame.minY + edge { speed = -min(1, (frame.minY + edge - finger.y) / edge) }
            else if finger.y > frame.maxY - edge { speed = min(1, (finger.y - frame.maxY + edge) / edge) }
            else { speed = 0 }
            guard speed != 0, finger.x >= frame.minX, finger.x <= frame.maxX else { return }
            let low = -scroll.adjustedContentInset.top
            let high = max(low, scroll.contentSize.height - scroll.bounds.height + scroll.adjustedContentInset.bottom)
            let y = min(high, max(low, scroll.contentOffset.y + speed * 220 * link.duration))
            scroll.setContentOffset(CGPoint(x: scroll.contentOffset.x, y: y), animated: false)
            movePreview()
        }
        func finishVisual(cancelled: Bool) {
            displayLink?.invalidate()
            displayLink = nil
            guard let lifted else { return }
            self.lifted = nil
            let destination = view?.cell
            let window = view?.window
            let changes = {
                lifted.transform = .identity
                if let destination, let window { lifted.frame = destination.convert(destination.bounds, to: window) }
                lifted.alpha = 0
            }
            if source.session.reduceMotion { changes(); lifted.removeFromSuperview() }
            else { UIView.animate(withDuration: 0.18, animations: changes) { _ in lifted.removeFromSuperview() } }
        }
    }
}

@MainActor final class WeakReorderHandle {
    weak var view: ReorderDragSource.HandleView?
    init(_ view: ReorderDragSource.HandleView) { self.view = view }
}
