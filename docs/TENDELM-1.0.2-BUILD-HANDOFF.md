# Tendelm 1.0.2 (3) — local build handoff

Status: **Tendelm 1.0.2 (3) was built, verified and delivered on November 5, 2026.** Private GitLab and Codemagic connections work. The source project is `https://gitlab.com/gajula.naithik/tendelm`, and Codemagic app ID is `6aecec9cee95bb28ae2a2832`. Browser automation was removed at the user's request; use command-line/API access only. See [the validation record](TENDELM-1.0.2-VALIDATION.md) for exact commits, test provenance and remaining device checks.

## Changes

- Time-since detail has adjacent Log a reset and Log a previous reset controls. Accessibility text sizes stack them. The new sheet accepts a past date/time; it keeps later events and explains an earlier initial start. Immediate Undo added reset removes that exact event. Scheduled start behavior remains.
- Settings → Data → Import from another app adds local daily CSV parsing, date-order clarification, a read-only preview and additive import. Streaks/Habitify documented daily fields plus simple CSV are supported; amounts and skipped/failed statuses are retained in notes. No schema or bundle-ID changes.
- Existing Thinking Orbs progress appears only while file reading/parsing is underway.
- Delivered app/widget/test target version: 1.0.2 (3). The previous 1.0.1 IPA was moved to the Recycle Bin after replacement verification.

## Validation boundary

Regression tests were authored for past-reset ordering, invalid/future dates, undo, scheduled trackers, persistence/backup round trips, documented CSV fields, quoted Unicode notes, ambiguous dates, DST, duplicate/conflicting data, repeat imports, keeping edits/unrelated records, goal-type conflicts, pending edits, identity conflicts and file limits. UI cases cover the reset sheet and import entry/help.

Codemagic build `6aecee22ab17f8deb75334e6` at commit `9873276123c734a7375c9ecc516d306f23c09d43` passed 813 unit tests with one pre-existing expected issue (814 total), plus 10 of 11 selected iPhone UI tests. The remaining test tried to tap the name field behind an open native calendar. Its dismissal now targets the native `PopoverDismissRegion` regardless of element type, preserving the date/edit/relaunch assertions. Production source is unchanged after that baseline.

Successful final build `6aecf815ab17f8deb7533888` at commit `376ba173b3a52bcbf8cce91706ec68871fb8d665` passed the corrected future-date test, two dark-mode tests, two iPad tests, and Release device build/package checks. Its explicit baseline mode refused production or unit-test changes before reusing passed results. Combined evidence includes 813 unit passes and 15 UI passes across runs, plus the expected unit issue. The regular workflow still runs the full selection. Evidence is under `.build/artifacts/codemagic-<build-id>/`.

No physical-device, complete VoiceOver, or large-import performance result is claimed. Real Streaks/Habitify exports must also be tried before promising full migration compatibility.

Static review includes the data mutation boundaries, source-documented format mappings and script/config consistency. A bounded free supporting review was checked against actual callers; the cross-habit completion-ID check was moved ahead of same-day skipping. Suggestions that assumed mutable externally constructed plans, invented SwiftData parent contexts or contradicted parser guards were not applied.

Checks actually run on Windows: `git diff --check`, Bash syntax validation of the new build script, Python AST parsing of the package verifier, YAML parsing of workflow files, and consistency checks for version 1.0.2/build 3 across every target. All passed. These are static checks, not Swift type checking or iOS tests.

## Build without GitHub

The `personal` branch includes `codemagic.yaml`, with a manually started `tendelm-ipa` workflow on a macOS M2 machine. No publishing, notifications or automatic build triggers are configured. Confirm the personal account's available free minutes before starting the build. GitLab CI/CD and Pages are disabled for the private source repository.

Copy the checkout to a Mac with Xcode 26.3+ and an iOS 18+ simulator. Keep the project, `Packages`, sources, tests, asset catalogs and scripts together. Network access is needed to resolve the existing pinned ThinkingOrbsKit dependency if it is not cached. A GitHub account is not required for public dependency downloads; private source transfer can use an approved independent route.

From the checkout, run:

```bash
bash Scripts/build-personal.sh
```

This runs the unit suite, focused iPhone UI/theme tests, dark-appearance and iPad checks, then a Release arm64 device build and package inspection. It uses a fresh ignored `.build-personal-*` directory and keeps full logs/results. The script itself uploads nothing; Codemagic collects the IPA, logs, summaries and screenshot attachments as private build artifacts. `TENDELM_SIMULATOR_ID` can select a particular iPhone simulator. The existing GitHub workflow remains available if account access returns.

Representative reset/import screenshots were inspected in light/dark, large text and iPad layouts. Automated coverage includes reset cancellation/save/undo/relaunch and parser/import regression cases. Full real Files-picker imports with representative third-party exports and physical-device acceptance remain pending. Run the relevant broader coverage for future fixes; native failures must be resolved before replacing the tested IPA.

Delivered **only `Tendelm-1.0.2.ipa`** to `C:\Users\naith\Desktop\ipa\My Projects (N3mo Studio)`, verified the copy, then moved the older Tendelm IPA to the Recycle Bin. Other apps were preserved. Keep logs, reports and archives outside that delivery folder, and retain the current IPA until a replacement passes verification.
