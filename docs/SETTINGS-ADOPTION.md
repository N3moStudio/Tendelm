# Native Settings Kit adoption — Tendelm

Baseline: b55a940. Final production implementation: d205ded203d60346d0efa2b10048f1148b6b7e98. Final native simulator run: 6aeff00124e1ec2375576207 (passed, 8 November 2026 UTC / 7 November Pacific).

The kit is retained verbatim under UI/NativeSettingsKit as the design/validation reference. Its gallery and package are not linked into Tendelm. Presentation patterns were adapted into the existing paper/ink/sage design system in TendelmSettingsStyle.swift, with retained notices. This avoids another runtime palette system and keeps every existing palette, independent System/Light/Dark policy and their saved raw values.

Changes: larger 70pt branded appearance card; compact rounded content with an idempotent one-category ordinary Dynamic Type adjustment (accessibility sizes unchanged); 52pt minimum native rows, 24pt group spacing, simpler unboxed icons; six existing palettes as larger selectable tiles; independent Solid/Liquid Glass settings navigation treatment. Content remains opaque. Reduce Transparency and Increase Contrast force the solid rendering path without rewriting the stored choice.

Existing navigation categories/destinations remain. No model, schema, bundle/App Group ID, backup importer/exporter, permission handler, entitlement, async cancellation or destructive handler changed. BackupSettingsContainer remains outside its Form and retains ownership of its existing presentations. A new personal.settingsSurface key is read without save-on-fallback; existing full reset already clears personal.* keys. The delivered Tendelm-1.0.5.ipa remains unchanged (10,732,630 bytes). No IPA or release was built by this adoption.

Feature inventory: SETTINGS-FEATURE-MAP.md, prepared before UI edits. The shared kit's eight themes are not added to this existing app: its eight-choice picker is optional under ADOPTION.md; Tendelm's six established habit palettes and brand canvas remain. Bloom/Ion gallery captures would not represent this app's adopted palette behavior.

Portable: kit validator passed 8 themes, 144 solid-color pairs (minimum 5.09:1), 28 documentation links and source-ownership guardrails. This describes kit tokens, not Tendelm's app-wide contrast. Git diff and simulator script shell syntax checks passed. Optional Tree-sitter check did not run because its optional parser packages are unavailable; native checks are the intended compile evidence. No local Xcode/Swift executable exists on this Windows host.

Initial native run 6aefead624e1ec2375576103 compiled the app and executed 842 unit tests: 841 passed plus the existing expected SwiftData observation issue (ObservationAfterFetchTests). It ran 14 UI tests: 13 passed; the maximum-text import test found duplicate accessibility snapshots for one text label. The test now scopes that lookup with firstMatch; its assertions remain, and maximum-text palette/surface interactions were added. Screenshot review also found that a shared foreground override suppressed native destructive colors. The override was removed, preserving each control's role and disabled styling. Superseded queued run 6aefefb424e1ec23755761f2 was cancelled; the successful final evidence is recorded below.

Initial native screenshots inspected: overview, appearance/palette in light and dark, maximum accessibility overview, import/export and Recently Deleted. The new card, grouping, wrapping and existing controls were present. Final captures confirm red Delete permanently and the sage Restore action. No production model/behavior fix was needed.

Pending physical-device/manual checks: VoiceOver spoken output; native edge-swipe gesture and interrupted transitions; Reduce Transparency/Increase Contrast system rendering (policy unit-tested); very narrow/landscape/resizable iPad and RTL/long translations; live notification permission denial/settings return and real Files provider/share cancellations. Simulator checks use isolated synthetic data and do not prove installation/signing, physical-device behavior, battery or performance. The standalone kit package/gallery is retained as reference and has not been natively compiled as a separate module by this adoption.

Final native validation: Xcode 26.6 (17F113), Swift 6.3.3, iOS Simulator 26.5, native exit code 0. Tested source is exactly d205ded203d60346d0efa2b10048f1148b6b7e98; subsequent changes are evidence/documentation only.

| Run | Device | Result |
|---|---|---|
| Unit | iPhone 17 Pro | 842 logical tests: 841 passed, 1 existing expected SwiftData issue; 0 unexpected failures |
| Settings/light | iPhone 17 Pro | 14 UI tests passed |
| Settings/dark | iPhone 17 Pro | 1 UI test passed |
| Settings/import | iPad Pro 13-inch (M5) | 2 UI tests passed |

All 17 UI checks passed with no skipped tests. They cover all six palettes, independent display/surface choices, relaunch persistence, keeping the pushed Appearance route across tab changes, Back taps, day-start controls, demo-store switching, JSON/helper return, paste import/review/cancel/repeat import, Today deletion/recovery/relaunch, and maximum-accessibility settings/palette/surface/import access. Unit coverage also retains the existing backup/migration/reset/store suites. The only distinct source compiler warning is the pre-existing unnecessary try in TimeSincePersistenceTests.swift:74; no new source warning was reported.

Inspected final native captures: iPhone light and dark overview, dark palette/surface, maximum accessibility overview/palette/surface/import, Recently Deleted, and iPad overview/appearance/import. The 70pt branded card is preserved; larger type stacks artwork and wraps labels; palette tiles become one column at accessibility sizes and expand across iPad; native Back and the host tabs remain. The final Recently Deleted image confirms the restored destructive red and normal sage action tint. This is inspected simulator evidence, not a phone/VoiceOver/gesture acceptance claim.

Machine-readable summaries: [Unit](validation/native-settings-kit/Unit-summary.json), [light UI](validation/native-settings-kit/Settings-summary.json), [dark UI](validation/native-settings-kit/Dark-summary.json), [iPad UI](validation/native-settings-kit/iPad-summary.json). Full logs, manifests and original images remain locally in .build/artifacts/settings-6aeff00124e1ec2375576207/.settings-check-nu0wul4O. Readable image copies are in .build/review/native-settings-{light,dark,appearance,accessibility,ipad}.png. The artifact contains no IPA. Use only tendelm-settings-checks / Scripts/check-settings.sh for simulator validation; the IPA workflow is separate and was not invoked.

Rollback: revert the adoption commits d205ded, 1bc1ef8 and c29fd6c in reverse chronological order, preserving unrelated later work. Existing settings and backup formats require no migration. The optional new surface key can remain unused; do not erase saved user data to undo presentation.
