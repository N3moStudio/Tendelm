# Calm cards and Time since

Date: 2026-11-04. Scope: the user's personal sideload edition.

The user wants Open Habit's compact contribution-grid cards inside Kadō's warm, quiet visual system, plus multiple independently named elapsed-time trackers. Logging an occurrence restarts that tracker, with no shame language or setup funnel.

Today already snapshots managed records into values, preserves IDs across dev-store swaps, and owns the existing quick-log actions. Reuse those actions and the existing OverviewMatrix daily-value rules. Keep the original list available.

Time since needs exact timestamps rather than daily completion records. Add two entities in schema V5 with a lightweight migration; leave V1–V4 immutable. Use value snapshots for rendering, a small mutation service, and include trackers and resets in JSON/CSV backups. Calendar dates drive the heatmap; elapsed durations deliberately use 24-hour days so travel and DST do not change elapsed time.

The Windows host has no Xcode. Use a private GitHub repository and a Mac runner for native unit/UI tests, screenshots, and an unsigned ARM64 IPA. A new app identity cannot use the upstream CloudKit container; this personal edition uses local storage and explicit backup. Preserve upstream source/license/branding and keep publishing out of scope.

Verification risks: fresh and upgraded storage, undo/history isolation, relaunch persistence, malformed imports, small screens, large text, dark mode, widget packaging, and preserving existing habit behavior.

No open product questions block the requested implementation.
