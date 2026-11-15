import SwiftUI
import Observation

/// Preview-only order. A valid drop is the only operation that writes storage.
@MainActor @Observable
final class ReorderSession {
    var activeID: UUID?
    private(set) var original: [UUID] = []
    private(set) var preview: [UUID] = []
    var reduceMotion = false

    func begin(_ id: UUID, among ids: [UUID], reduceMotion: Bool) {
        guard ids.contains(id), Set(ids).count == ids.count else { return }
        self.reduceMotion = reduceMotion
        original = ids
        preview = ids
        activeID = id
    }

    func ordered<T: Identifiable>(_ items: [T]) -> [T] where T.ID == UUID {
        guard activeID != nil, Set(items.map(\.id)) == Set(original) else { return items }
        let lookup = Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0) })
        return preview.compactMap { lookup[$0] }
    }

    func accepts(_ target: UUID) -> Bool { activeID != nil && original.contains(target) }

    func hover(over target: UUID) {
        guard let activeID, let source = preview.firstIndex(of: activeID),
              let destination = preview.firstIndex(of: target), source != destination else { return }
        withAnimation(reduceMotion ? nil : .snappy(duration: 0.22, extraBounce: 0)) {
            preview.move(fromOffsets: IndexSet(integer: source), toOffset: destination > source ? destination + 1 : destination)
        }
    }

    func drop(commit: ([UUID]) -> Bool) -> Bool {
        guard activeID != nil else { return false }
        let succeeded = preview == original || commit(preview)
        cancel()
        return succeeded
    }

    func cancel() {
        withAnimation(reduceMotion ? nil : .snappy(duration: 0.22, extraBounce: 0)) {
            activeID = nil
            original = []
            preview = []
        }
    }
}

@MainActor
struct ReorderDropDelegate: @preconcurrency DropDelegate {
    let session: ReorderSession
    let target: UUID
    let commit: ([UUID]) -> Bool

    func validateDrop(info: DropInfo) -> Bool { session.accepts(target) }
    func dropEntered(info: DropInfo) { session.hover(over: target) }
    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: session.accepts(target) ? .move : .forbidden)
    }
    func performDrop(info: DropInfo) -> Bool {
        guard session.accepts(target) else { return false }
        return session.drop(commit: commit)
    }
}
