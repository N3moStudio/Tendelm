# Hold-and-drag ordering

Scope: Today list/cards and Time Since. Subtle 44-point grips sit outside the existing Delete context-menu content. A UIKit drag interaction on the grip owns the native lift and end callbacks. A local-only drag session previews row movement with a short, non-bouncy settling animation; only a valid drop saves. Cancellation, leaving the screen, backgrounding, or a changed item set discard the preview. Reduce Motion removes the explicit transition. Accessible Move up/down actions use the same save path.

Habits retain their existing sortOrder and scheduled sections; moving one section only replaces its slots in the global active order. Time Since gains nullable sortOrder through V7 lightweight migration from V6. Old trackers retain chronological fallback until reordered; starts, resets and scores are independent of order. New tracker backup JSON and optional CSV tracker_order preserve ordering, while old JSON/16-column CSV remain readable. Recently Deleted payloads use the same Codable tracker snapshot. Save errors roll back and surface an alert.

Preserved: themes/native bars, detail navigation, reset/Undo, hold-to-delete, schedules and history. This task is source + simulator validation only; no IPA packaging or replacement requested.

Initial run 43773625685: all 850 unit tests passed, including V6 migration and ordering backups. Native drag tests exposed the row context menu taking priority, plus habit-grip accessibility being merged into the navigation label. Replaced the conflicting native List onMove path with an isolated UIKit drag source, local-only staged reorder/drop, and a grip outside the habit NavigationLink. The existing Delete content/menu remains. Added four session/cancellation tests; reusing the unchanged persistence test results.

Validation pending: unit suite including real V6 disk migration, backup order, visible-section slot rules; native long-press drag/relaunch checks for list, cards and trackers, plus existing deletion/recovery flows. Physical-device gesture feel and frame pacing require device verification.
