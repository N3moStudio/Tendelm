# Tendelm 1.0.2 (3) — local build handoff

Status: implementation and cloud build configuration prepared; **not built or installed**. The user resumed build work and authorized private GitLab hosting plus Codemagic builds. GitLab authentication works, and the private project is `https://gitlab.com/gajula.naithik/tendelm`. Codemagic still needs authentication. Browser automation was removed at the user's request; use command-line/API access and user-controlled sign-in only.

## Changes

- Time-since detail has adjacent Log a reset and Log a previous reset controls. Accessibility text sizes stack them. The new sheet accepts a past date/time; it keeps later events and explains an earlier initial start. Immediate Undo added reset removes that exact event. Scheduled start behavior remains.
- Settings → Data → Import from another app adds local daily CSV parsing, date-order clarification, a read-only preview and additive import. Streaks/Habitify documented daily fields plus simple CSV are supported; amounts and skipped/failed statuses are retained in notes. No schema or bundle-ID changes.
- Existing Thinking Orbs progress appears only while file reading/parsing is underway.
- Next app/widget/test target version: 1.0.2 (3). The previous IPA remains 1.0.1 (2).

## Validation boundary

Regression tests were authored for past-reset ordering, invalid/future dates, undo, scheduled trackers, persistence/backup round trips, documented CSV fields, quoted Unicode notes, ambiguous dates, DST, duplicate/conflicting data, repeat imports, keeping edits/unrelated records, goal-type conflicts, pending edits, identity conflicts and file limits. UI cases cover the reset sheet and import entry/help.

These new Swift tests have **not run**. No new Swift compilation, simulator screenshot, physical-device interaction, accessibility layout or large-import performance result is claimed. Real Streaks/Habitify exports must also be tried before promising full migration compatibility. Existing 1.0.1 evidence does not validate this change.

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

Before delivering, inspect the new reset/import screens in light/dark, large text and iPad layouts, and exercise the real Files picker, cancel, ambiguous dates, repeated import and relaunch with representative exports. Verify that failures do not alter existing data. Run the broader UI coverage relevant to any fixes. Native test failures must be resolved before treating the IPA as the latest tested version.

On successful build/testing, copy **only the IPA** to `C:\Users\naith\Desktop\ipa\My Projects (N3mo Studio)`, then replace the older Tendelm IPA. Preserve other apps. Keep logs, reports and archives outside that delivery folder. The current IPA must remain until the new build passes verification.
