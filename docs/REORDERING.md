# Hold-and-drag ordering

Scope: Today list/cards and Time Since. Subtle 44-point grips sit outside the existing Delete context-menu content. Native List movement owns lift, gap movement, scrolling, cancellation and settling; Reduce Motion disables explicit animation transactions. Accessible Move up/down actions use the same save path.

Habits retain their existing sortOrder and scheduled sections; moving one section only replaces its slots in the global active order. Time Since gains nullable sortOrder through V7 lightweight migration from V6. Old trackers retain chronological fallback until reordered; starts, resets and scores are independent of order. New tracker backup JSON and optional CSV tracker_order preserve ordering, while old JSON/16-column CSV remain readable. Recently Deleted payloads use the same Codable tracker snapshot. Save errors roll back and surface an alert.

Preserved: themes/native bars, detail navigation, reset/Undo, hold-to-delete, schedules and history. This task is source + simulator validation only; no IPA packaging or replacement requested.

Validation pending: unit suite including real V6 disk migration, backup order, visible-section slot rules; native long-press drag/relaunch checks for list, cards and trackers, plus existing deletion/recovery flows. Physical-device gesture feel and frame pacing require device verification.
