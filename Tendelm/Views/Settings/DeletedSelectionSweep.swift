import Foundation

/// A gesture works from its starting snapshot. Reversing direction removes
/// the overshot range without discarding selections made before the gesture.
struct DeletedSelectionSweep {
    let anchor: UUID
    let orderedIDs: [UUID]
    let selectedIDs: Set<UUID>

    func selection(through target: UUID) -> Set<UUID> {
        let available = Set(orderedIDs)
        let baseline = selectedIDs.intersection(available)
        guard let first = orderedIDs.firstIndex(of: anchor),
              let last = orderedIDs.firstIndex(of: target) else { return baseline }
        let range = Set(orderedIDs[min(first, last)...max(first, last)])
        return baseline.contains(anchor) ? baseline.subtracting(range) : baseline.union(range)
    }
}
