import Foundation
import Testing
@testable import Tendelm

@Suite("Drag preview and cancellation") @MainActor
struct ReorderSessionTests {
    private struct Item: Identifiable { let id: UUID }

    @Test("Hover previews order without saving; cancellation restores it")
    func cancelPreview() {
        let items = [Item(id: UUID()), Item(id: UUID()), Item(id: UUID())]
        let session = ReorderSession()
        session.begin(items[2].id, among: items.map(\.id), reduceMotion: true)
        session.hover(over: items[0].id)
        #expect(session.ordered(items).map(\.id) == [items[2].id, items[0].id, items[1].id])
        session.cancel()
        #expect(session.ordered(items).map(\.id) == items.map(\.id))
        #expect(session.activeID == nil)
    }

    @Test("Drop commits once and ending the native session cannot commit again")
    func singleCommit() {
        let a = UUID(), b = UUID()
        let session = ReorderSession()
        var commits: [[UUID]] = []
        session.begin(b, among: [a, b], reduceMotion: true)
        session.hover(over: a)
        #expect(session.drop { commits.append($0); return true })
        session.cancel()
        #expect(!session.drop { commits.append($0); return true })
        #expect(commits == [[b, a]])
    }

    @Test("Other sections and external IDs never become drop targets")
    func scope() {
        let a = UUID(), b = UUID(), outside = UUID()
        let session = ReorderSession()
        session.begin(a, among: [a, b], reduceMotion: true)
        #expect(!session.accepts(outside))
        session.hover(over: outside)
        #expect(session.preview == [a, b])
    }

    @Test("Failed save clears the preview and returns the original display")
    func failedSave() {
        let items = [Item(id: UUID()), Item(id: UUID())]
        let session = ReorderSession()
        session.begin(items[0].id, among: items.map(\.id), reduceMotion: true)
        session.hover(over: items[1].id)
        #expect(!session.drop { _ in false })
        #expect(session.ordered(items).map(\.id) == items.map(\.id))
    }
}
