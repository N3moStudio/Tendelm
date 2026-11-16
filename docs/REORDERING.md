# Hold-and-drag ordering

Scope: Today list/cards and Time Since. Hold the 44-point handle and move up or down. The handle recognizer is attached to its containing native list cell, with touch admission restricted to the handle bounds; this lets it arbitrate with the row context menu without taking over normal row taps. Holding the item outside the handle still offers Delete.

A lifted row snapshot follows the finger. Nearby rows settle with a short, non-bouncy animation, and the list scrolls at its edges. Only a valid release saves. Cancellation, leaving the screen, backgrounding, or a changed item set discard the staged order. Reduce Motion removes the explicit transitions. VoiceOver Move up/down actions use the same storage path.

Habits retain their existing sortOrder and scheduled sections; moving within a section replaces only its slots in the global active order. Time Since gains nullable sortOrder through V7 lightweight migration from V6. Old trackers retain chronological fallback until reordered. Starts, resets, scores and histories are independent of ordering. JSON and optional CSV tracker_order preserve the new ordering; legacy JSON and 16-column CSV remain readable. Recently Deleted uses the same Codable tracker snapshot. Save failures roll back and show an alert.

Preserved: themes/native bars, detail navigation, New Tracker and cancellation, reset/Undo, hold-to-delete, schedules and history. No IPA was packaged or replaced for this task.

## Verification

- Run 43773625685: 850 unit tests passed, including real V6 disk migration, ordering persistence/reopen, legacy and ordered backups, and section-slot rules. Its initial UI failures exposed the competing row menu; that initial drag implementation was replaced.
- Run 43781204184, application source 14e0ffd: four additional drag-session tests passed; all five iPhone 16e/iOS 26.2 UI tests passed. Covered physical hold-and-drag in Today list, Today cards and Time Since; order after app relaunch; tracker detail navigation; existing deletion/recovery flows. Native screenshots of all three reordered layouts inspected.
- Run 43783164300, commit 7e754fc (application source unchanged): the extended tracker test passed, verifying New Tracker is hittable after reordering, its editor opens and cancels, order survives relaunch, and detail navigation works. After-drag and after-cancel screenshots show the New Tracker button. A previous capture omitted it, so this received an explicit follow-up check.
- Four session tests cover staged-only movement, cancellation, one commit per release, invalid/cross-section targets and save failure.
- The earlier isolated run 43779937535 exceeded its cold-start test allowance after successful drag/order assertions, before completing relaunch. Focused checks now boot the simulator explicitly and use bounded allowances matching the other native checks.

Physical-device gesture feel, long-distance edge scrolling, iPad layout and frame pacing remain unverified. Successful gesture tests and static screenshots do not establish on-device animation performance. Successful-run videos were not retained by XCTest.
