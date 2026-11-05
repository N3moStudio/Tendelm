# Tendelm 1.0.2 (3) validation

Delivered privately on November 5, 2026. No public release, TestFlight upload or App Store submission was made.

## Build and provenance

- Built commit: `376ba173b3a52bcbf8cce91706ec68871fb8d665`.
- [Successful Codemagic run](https://codemagic.io/app/6aecec9cee95bb28ae2a2832/build/6aecf815ab17f8deb7533888): native exit code 0, evidence collection complete.
- Xcode 26.6 (17F113), Swift 6.3.3, macOS 26.5.1; simulator iOS 26.5 on a Mac M2.
- Production and unit-test source match baseline `9873276123c734a7375c9ecc516d306f23c09d43`. Later commits change only the UI test's native-calendar dismissal and build/evidence scripts.

| Check | Result | Run |
| --- | --- | --- |
| Unit suite | 813 passed; one pre-existing expected issue, 814 total | `6aecee22ab17f8deb75334e6` |
| Other selected light iPhone UI cases | 10 passed | `6aecee22ab17f8deb75334e6` |
| Future start, edit and relaunch | 1 passed after test-harness correction | `6aecf815ab17f8deb7533888` |
| Dark iPhone checks | 2 passed | `6aecf815ab17f8deb7533888` |
| iPad checks | 2 passed | `6aecf815ab17f8deb7533888` |
| Release device build and package inspection | Passed | `6aecf815ab17f8deb7533888` |

These are combined results, not a claim that the entire suite ran in the final job. The explicit resume mode checks the baseline diff before reuse. Normal builds run the complete configured selection. The earlier future-date UI failure was caused by tapping behind an open native calendar; the corrected test dismisses its native popover and retains its original assertions.

The Release device log had no warnings or errors. Simulator test compilation reported a redundant `try` in a persistence test and skipped AppIntents extraction for the test runner; neither failed the build.

## Delivered package

- File: `C:\Users\naith\Desktop\ipa\My Projects (N3mo Studio)\Tendelm-1.0.2.ipa`.
- Size: 10,433,100 bytes; version 1.0.2, build 3; minimum iOS/iPadOS 18.0.
- Main bundle: `com.n3mostudio.tendelm`; widget: `com.n3mostudio.tendelm.TendelmWidgets`.
- Native arm64 iOS device executables; not simulator binaries or FairPlay-encrypted content. No embedded provisioning profile; personal sideload signing is required.
- Archive integrity, app/widget identities, versions, assets and notices passed inspection. The downloaded package matched the CI receipt, and the delivered copy matched the inspected source.
- The prior Tendelm IPA was moved to the Recycle Bin. No logs, ZIPs or verification sidecars were added to the delivery folder; other apps were untouched.

## Evidence and limits

Local evidence is retained under `.build/artifacts/codemagic-6aecee22ab17f8deb75334e6/` and `.build/artifacts/codemagic-6aecf815ab17f8deb7533888/`. The final directory contains the build receipt, test summaries, full logs, UI result bundles, screenshots and package inspection.

Representative light and dark tracker/reset/import screens, large-text tracker detail and iPad import layouts were visually inspected. Automated cases cover previous-reset cancellation/save/undo/relaunch, future starts, themes and import entry/help; unit cases cover persistence and additive import behavior.

Physical iPhone installation, signing-dependent widget sharing, gestures, complete VoiceOver, performance and real third-party export files remain unverified. Full Files-picker imports with representative Streaks/Habitify exports still need device acceptance. Simulator and package checks do not establish those outcomes.
