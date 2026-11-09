import Foundation
import Testing
@testable import Tendelm

struct DeletedSelectionSweepTests {
    let ids = (0..<6).map { _ in UUID() }

    @Test func fastDragSelectsSkippedRowsAndReversesWithoutLosingExistingSelections() {
        let sweep = DeletedSelectionSweep(anchor: ids[1], orderedIDs: ids, selectedIDs: [ids[5]])
        #expect(sweep.selection(through: ids[4]) == Set(ids[1...5]))
        #expect(sweep.selection(through: ids[2]) == [ids[1], ids[2], ids[5]])
        #expect(sweep.selection(through: ids[0]) == [ids[0], ids[1], ids[5]])
    }

    @Test func startingOnSelectedRowDeselectsRangeAndReversalRestoresBaseline() {
        let sweep = DeletedSelectionSweep(anchor: ids[4], orderedIDs: ids, selectedIDs: Set(ids))
        #expect(sweep.selection(through: ids[1]) == [ids[0], ids[5]])
        #expect(sweep.selection(through: ids[3]) == [ids[0], ids[1], ids[2], ids[5]])
    }

    @Test func missingRowsNeverEnterTheSelection() {
        let stale = UUID()
        let sweep = DeletedSelectionSweep(anchor: stale, orderedIDs: ids, selectedIDs: [stale, ids[2]])
        #expect(sweep.selection(through: ids[4]) == [ids[2]])
    }
}
