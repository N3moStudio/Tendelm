import SwiftData

extension ModelContainer {
    /// Tests explicitly save when checking persistence. A queued autosave can
    /// otherwise fire after a fixture's temporary store has been removed,
    /// trapping inside SwiftData's timer on iOS 18.5. This is test-only; the
    /// application's autosave behavior is unchanged.
    @MainActor
    func usingExplicitTestSaves() -> ModelContainer {
        mainContext.autosaveEnabled = false
        return self
    }
}
