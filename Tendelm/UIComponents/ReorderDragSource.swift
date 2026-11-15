import SwiftUI
import UIKit

/// A real drag interaction on the grip, separate from List's row context menu.
/// UIKit supplies the lift preview and always reports the session ending.
struct ReorderDragSource: UIViewRepresentable {
    static let typeIdentifier = "com.n3mostudio.tendelm.local-reorder"
    let id: UUID
    let begin: () -> Void
    let end: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        view.isAccessibilityElement = false
        let interaction = UIDragInteraction(delegate: context.coordinator)
        interaction.isEnabled = true
        interaction.allowsSimultaneousRecognitionDuringLift = false
        view.addInteraction(interaction)
        return view
    }

    func updateUIView(_ view: UIView, context: Context) { context.coordinator.source = self }

    final class Coordinator: NSObject, UIDragInteractionDelegate {
        var source: ReorderDragSource
        init(_ source: ReorderDragSource) { self.source = source }

        func dragInteraction(_ interaction: UIDragInteraction, itemsForBeginning session: any UIDragSession) -> [UIDragItem] {
            source.begin()
            let id = source.id
            let provider = NSItemProvider()
            provider.registerDataRepresentation(forTypeIdentifier: ReorderDragSource.typeIdentifier, visibility: .ownProcess) { completion in
                completion(Data(id.uuidString.utf8), nil)
                return nil
            }
            let item = UIDragItem(itemProvider: provider)
            item.localObject = id
            return [item]
        }

        func dragInteraction(_ interaction: UIDragInteraction, sessionWillBegin session: any UIDragSession) {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }

        func dragInteraction(_ interaction: UIDragInteraction, sessionDidEnd session: any UIDragSession) { source.end() }
        func dragInteraction(_ interaction: UIDragInteraction, sessionIsRestrictedToDraggingApplication session: any UIDragSession) -> Bool { true }
        func dragInteraction(_ interaction: UIDragInteraction, sessionAllowsMoveOperation session: any UIDragSession) -> Bool { true }

        func dragInteraction(_ interaction: UIDragInteraction, previewForLifting item: UIDragItem, session: any UIDragSession) -> UITargetedDragPreview? {
            guard let sourceView = interaction.view else { return nil }
            var ancestor: UIView? = sourceView
            while let view = ancestor {
                let content: UIView?
                if let cell = view as? UICollectionViewCell { content = cell.contentView }
                else if let cell = view as? UITableViewCell { content = cell.contentView }
                else { content = nil }
                if let content {
                    let parameters = UIDragPreviewParameters()
                    parameters.backgroundColor = .clear
                    parameters.visiblePath = UIBezierPath(roundedRect: content.bounds, cornerRadius: 18)
                    return UITargetedDragPreview(view: content, parameters: parameters)
                }
                ancestor = view.superview
            }
            return UITargetedDragPreview(view: sourceView)
        }
    }
}
