# Tendelm 1.0.4 (5)

Status: completed and delivered. The final private build passed all selected checks and package inspection. Only `Tendelm-1.0.4.ipa` was placed in the delivery folder, replacing Tendelm 1.0.3 after verification.

## Change

Added native Paste buttons for Tendelm backups and external daily habit history. Both use their existing review/confirmation logic: backups merge by UUID and update matching records; external history adds missing days without overwriting existing entries. File import remains available. Settings links open json.site for JSON backups and CSVJSON for CSV conversion in a system Safari sheet, matching Elsepin's Done → Paste → review flow. No automatic file upload, clipboard polling, JavaScript bridge or import-on-return is used.

The external importer now accepts raw CSV or an array of daily row objects produced by the helper. It converts rows through the existing CSV writer/parser, preserving validated IDs, notes, date-order choices and repeat-import behavior. It rejects malformed, oversized, nested and non-daily JSON before writes. User-pasted links and empty/multiple clipboard inputs receive a clear error.

The 1.0.3 six-second recent Undo, swipe deletion and dark-mode text contrast fix are included. No schema, bundle ID, app-group or backup-format change.

## Verification

Source commit: `a07480b324029a3bf15f3f355a540569959a2981`.
Private [Codemagic run](https://codemagic.io/app/6aecec9cee95bb28ae2a2832/build/6aed7668ab17f8deb753571c).

Initial run `6aed70e2ab17f8deb75355cd` failed to compile a test-only screenshot helper that redeclared an inherited method. The correction reuses the existing base-class helper. No passing test evidence is claimed from that attempt; its full console is retained under `.build/artifacts/`.

Run `6aed71bcab17f8deb75355fe` passed the full unit suite and 16 of 18 light iPhone UI tests. The backup review and JSON helper tests found that presentation from the lazy Settings section did not open a sheet. The same history paste/cancel/repeat-import flow passed on its separate Form. The focused correction keeps the backup presentation state and modifiers on a container around the complete Settings Form; its one fixed section retains the same rows and actions. The next run executes all four paste UI tests before the broader UI selection, without duplicating or skipping tests.

Local diff/static checks passed. Native workflow requested the complete unit suite, focused iPhone UI suite including four new paste tests, dark iPhone backup paste and iPad history paste, then a Release arm64 build and package inspection. No test baseline was requested for this production change.

### Final results

- Unit tests: **828 passed, zero failures, one pre-existing expected issue** (829 total).
- Paste iPhone UI: **4 passed**. Backup paste/cancel/import/relaunch and json.site open/Done/return-to-Paste both passed after moving the presentation host.
- Existing light iPhone UI: **14 passed**; dark iPhone: **4 passed**; iPad: **4 passed**. Total UI checks: **26 passed, zero failures**.
- Release arm64 app and widget: built successfully; device-build log has zero warnings/errors. The unit build retains an existing unnecessary-`try` warning in `TimeSincePersistenceTests` and test-bundle App Intents metadata notices.
- Xcode 26.6 (17F113), Swift 6.3.3. Native exit code 0; evidence collection complete; no reused baseline.
- IPA: version **1.0.4**, build **5**, **10,510,412 bytes**. ZIP, native device architecture, bundle/widget identifiers, notices and absence of test bundles passed inspection. Local artifact and delivered copy matched the CI package internally.

Evidence directory: `.build/artifacts/codemagic-6aed7668ab17f8deb753571c/`. Extracted logs, five test summaries, attachments, package inspection and receipt are in `extracted/.build-personal-hGWcFFSZ/`; native result bundles are archived alongside them.

Reviewed final screenshots of the light/dark backup confirmation, Settings paste/helper controls and iPad history preview. Actions and contents are visible and readable. The existing long backup-sheet title uses native ellipsis on iPhone; it does not obscure Cancel or Import. The dark Undo contrast correction is unchanged from the validated 1.0.3 revision and its interaction suite passed again.

Delivered file: `C:\Users\naith\Desktop\ipa\My Projects (N3mo Studio)\Tendelm-1.0.4.ipa`. The previous Tendelm IPA was moved to the Recycle Bin only after the new copy was checked. Other projects' IPAs were preserved. No logs, ZIPs or verification sidecars were delivered there. The GitLab project was verified private, with Pages and GitLab pipelines disabled.

New tests cover clipboard validation, CSV/JSON parity, Unicode and quoting, optional columns, scalar values, date ambiguity, malformed input, read-only preview, repeated import, persistence/relaunch, cancellation and the helper's Done return. Debug-only synthetic clipboard content is excluded from Release builds.

Physical-device sideload installation, real source-app exports, website file selection/copy, VoiceOver and large-text acceptance of these new controls remain pending. Simulator helper coverage opens the public page and returns; it does not upload a real backup or establish the website's privacy behavior.
