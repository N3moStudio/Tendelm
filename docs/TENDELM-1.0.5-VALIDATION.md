# Tendelm 1.0.5 (6)

Status: built privately, verified and delivered. Only Tendelm-1.0.5.ipa was placed in the delivery folder. Tendelm 1.0.4 was moved to the Recycle Bin after the new copy was verified; other projects were not modified.

## Changes

Long-press menus in Today (list/cards), Overview and Time since contain Delete. Deletion moves the item and its history into Recently Deleted for 30 days. The recovery screen supports individual and selected restores, Select All/Deselect All, selected permanent deletion and Delete All. A native alert with visible Cancel confirms the exact captured selection. Archived habits and detail deletion use the same recovery store. Existing reset-history swipe deletion and scoped six-second Undo remain.

Settings are grouped into appearance, habit controls, data and about. Import & export preserves file import, native Paste and review, with inline json.site/CSVJSON instructions and a system Safari Done return. Appearance choices remain independently available. Large accessibility text uses stacked subtitles and Paste controls. Typed counter entry remains available by tapping the value in habit detail; iOS 26.5 needs a tap in the field before typing.

Privacy & reset explains that updates retain storage and backup restores merge matching identities. Erase all data clears regular/demo records, histories, Recently Deleted, app preferences, notifications and app-generated temporary exports. Inactive migration copies and widget snapshots are removed. Files exports and iOS permission grants remain.

## Data compatibility

V6 adds one recovery model; shipped V5 model definitions remain unchanged. V5-to-V6 migration is lightweight. Recovery and live deletion save in one transaction; restore validates all selected entries and identities before writes. Failure rollback, expiry, collisions, corrupt payloads, pending edits, restart and migration preservation have native unit coverage. Backup format 2 and bundle/widget identities remain unchanged. Recovery copies and appearance settings are excluded from exports.

## Verification

Packaged source commit: 0989f806e0cf01a8e0d2aa9c62745041d576d27b.

- [Baseline run](https://codemagic.io/app/6aecec9cee95bb28ae2a2832/build/6aeebce824e1ec23755711d9), source 755da7f7324543da2b30ec55cece07d187cb9acc: 838 unit tests passed with one pre-existing expected issue (839 total), and all 9 focused import/recovery UI tests passed. The broader UI run passed 19/22; failures were an old footer expectation and two drivers assuming autofocus despite documented iOS 26.5 tap-first behavior.
- [Final run](https://codemagic.io/app/6aecec9cee95bb28ae2a2832/build/6aeec45124e1ec237557130a): all 22 broader light iPhone UI tests, 5 dark iPhone tests and 5 iPad tests passed. The final source changes only those two UI test files and the guarded build script. A strict Git comparison verified identical production code to the baseline before reusing its unit and focused UI results. Normal builds continue to run the full selection; the resume override was supplied for this build only.
- Combined relevant coverage: 838 unit passes, one expected issue, and 41 UI passes. The final run rechecked Overview day editing, day-start selection, demo-mode swaps, theme switching, counter/timer typed replacement, time-since dates/history/Undo, imports and cross-device deletion/recovery. Full reset cancellation/confirmation and persistence after relaunch passed in the identical-source baseline.
- Release arm64 app and widget built successfully. Device build log contains no warnings or errors. Xcode 26.6 (17F113), Swift 6.3.3, iOS 26.5 simulators. Native exit 0 and evidence collection complete.
- IPA inspection passed locally and in CI: version 1.0.5, build 6, minimum iOS 18.0, 10,732,630 bytes, device arm64 executables, correct bundle/widget identifiers, intact archive, retained notices, no test bundles. This is the unsigned personal-sideload package; the delivered copy matched the inspected CI artifact internally.

Final evidence: .build/artifacts/codemagic-6aeec45124e1ec237557130a/.build-personal-ZVx2IDSD/. Baseline evidence: .build/artifacts/codemagic-6aeebce824e1ec23755711d9/.build-personal-KhmmUPKy/. Logs, summaries, screenshots and receipts remain in the source workspace.

Reviewed captures of grouped Settings, import controls at accessibility text size, recovery and selection, dark recovery, iPad Settings and typed counter entry. No layout overlap blocked the reviewed actions. The automated coverage is not a full VoiceOver or color-contrast audit.

Earlier attempts found test-helper scope and localized-subtitle compile errors, context-menu XCTest idle allowances, accessibility text compression and confirmation-popover placement. Those were corrected before the final artifact. Failed-run evidence is retained under .build/artifacts; none of those attempts produced the delivered IPA.

## Delivery and device acceptance

Delivered: C:\Users\naith\Desktop\ipa\My Projects (N3mo Studio)\Tendelm-1.0.5.ipa. GitLab visibility was rechecked as private; branch personal. No public release or browser/desktop control was used.

Signed sideload installation, actual phone gestures, VoiceOver interaction, real source-app exports and website file selection/copy remain device checks. Simulator and package success do not prove signing, widget entitlements, battery behavior or provider round trips. Export a backup before testing a destructive reset; saved Files backups are deliberately outside the in-app reset.
