import Foundation
import SwiftData
import TendelmCore

/// Rebuilds the local UN pending-request set from SwiftData. Paired
/// with `WidgetReloader` — any mutation that reloads widgets should
/// also resync reminders so a just-completed day stops firing.
///
/// Safe to call even when `ActiveScheduler.shared` hasn't been
/// primed yet (early init); it's a no-op in that case.
@MainActor
enum RemindersSync {
    // Preserve mutation order across async notification-center calls.
    // The final empty snapshot after erasure must run after any older schedule.
    private static var pending: Task<Void, Never>?

    static func rescheduleAll(using context: ModelContext) {
        guard let scheduler = ActiveScheduler.shared.get() else { return }
        let habits = (try? context.fetch(FetchDescriptor<HabitRecord>())) ?? []
        let completions = (try? context.fetch(FetchDescriptor<CompletionRecord>())) ?? []
        let habitSnapshots = habits.map(\.snapshot)
        let completionSnapshots = completions.compactMap(\.snapshot)
        let previous = pending
        pending = Task { [habitSnapshots, completionSnapshots] in
            await previous?.value
            await scheduler.rescheduleAll(
                habits: habitSnapshots,
                completions: completionSnapshots
            )
        }
    }
}
