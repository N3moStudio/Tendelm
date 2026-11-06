# Tendelm 1.0.3 (4)

Status: completed. The functional 1.0.3 build and the final text-contrast correction passed native checks and package inspection. The corrected IPA replaced the first 1.0.3 copy in the user's delivery folder.

## Change

Time-since cards and details now offer one recent Undo action in a bottom-right capsule. It expires after six seconds (20 when VoiceOver is enabled). It is cleared after undo, navigation away or backgrounding; opening an editor also clears it. A newer successful change replaces the pending action. Undo never falls back to deleting older history.

History reset rows expose native trailing Delete on a left swipe. Deleting one reset preserves the other events and initial start; a fresh Undo can restore the deleted event with its original ID and date. The start row remains editable through the tracker editor, not deletable as a reset. Mutations are saved before displaying Undo. Failure rolls back through the existing store, and receipts reverse individual events instead of restoring an old tracker snapshot.

The popup uses existing palette colors, native button styling, light haptic feedback and a reduced-motion-aware fade. No schema, bundle ID, app-group or backup-format changes.

## Checks requested

- Core expiry boundary, exact-event reversal, deletion/restoration of oldest/middle/newest entries, unrelated tracker/start edits and persistence identity.
- iPhone popup expiry, one-action behavior, cross-tracker replacement, swipe deletion/restoration/relaunch, previous resets and large text.
- Dark iPhone and iPad deletion/Undo coverage, plus existing screen/import checks.
- Full unit suite, existing focused personal/theme UI tests, Release arm64 device build and package inspection.

Source commit: `0fe4154f3e22c55736ba522ed102a972a59e2703`.
Private [Codemagic run](https://codemagic.io/app/6aecec9cee95bb28ae2a2832/build/6aed0918ab17f8deb7533dcf).
Evidence directory: `.build/artifacts/codemagic-6aed0918ab17f8deb7533dcf/`.

The full functional run passed 820 unit tests, with one pre-existing expected issue, plus 14 light iPhone, three dark iPhone and three iPad UI tests. The Release arm64 app and widget built successfully, with zero warnings/errors in the device-build log.

Screenshot review found insufficient Undo text contrast in dark mode. Commit `9fe6aa26f31dfafb35ba7a62dbfea44bfb4165d3` changed only that label's foreground to the existing background color. [Final Codemagic run](https://codemagic.io/app/6aecec9cee95bb28ae2a2832/build/6aed0db7ab17f8deb7533f0c) passed one light iPhone, three dark iPhone and three iPad UI tests, plus the Release build and package inspection. It reused the full functional baseline above under an exact color-only diff guard. Final dark screenshots confirmed readable dark ink on the mint Undo capsule.

Final evidence: `.build/artifacts/codemagic-6aed0db7ab17f8deb7533f0c/`. Receipt native exit code: 0; evidence collection: complete. Delivered `Tendelm-1.0.3.ipa`, 10,465,536 bytes, version 1.0.3 build 4, in `C:\Users\naith\Desktop\ipa\My Projects (N3mo Studio)`. Internal package and copied-file verification matched. No extra evidence files were placed in that folder.

Physical-device installation, gestures and full VoiceOver acceptance remain separate from simulator and package verification.
