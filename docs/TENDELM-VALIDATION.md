# Tendelm 1.0.0 (1) — personal build evidence

The device IPA, source tests, simulator checks, screenshots, independent Mac/local package inspection, REA inventory, and isolated reset-guard review experiment are complete.

## Delivered artifact

- File: `C:\Users\naith\Downloads\Tendelm-1.0.0.ipa`
- Version/build: **1.0.0 (1)**; iOS/iPadOS **18.0+**; **10,269,374 bytes**.
- SHA-256: `7a74c8fbe95da9a871a3dfdf244ffff7ad50e5b2ae15e380b23c426361cefa61`.
- App ID: `com.n3mostudio.tendelm`; widget ID: `com.n3mostudio.tendelm.TendelmWidgets`.
- Built implementation: `08c520bf7a1d0672aff42ad338e4936935db98ce`, Xcode **26.3**, macOS runner.
- [Build and simulator evidence](https://github.com/N3moStudio/Tendelm/actions/runs/41957168032): all compilation, unit, and UI steps passed. The subsequent package checker initially rejected the ZIP's harmless `Payload/` directory entry. That checker was corrected; the existing IPA passed locally, without changing or rebuilding app code.
- [Independent artifact review](https://github.com/N3moStudio/Tendelm/actions/runs/41958494976) passed at validation commit `49c3fc2cc6b89e76db69193f7eb3cb7cfa6d81c8`, reusing that exact IPA. Later commits change validation tools and documentation only; the app, package, widget, project, and test trees match the built implementation.
- No provisioning profile is included: the user's sideloading tool must sign the app. No physical installation is claimed.

| Check | Result |
| --- | --- |
| Full unit suite, iPhone 16 Pro / iOS 18.5 | 781 passed, 1 expected issue, 0 unexpected failures; 782 test declarations including 37 parameterized tests |
| Personal iPhone UI suite, light | 4 passed |
| iPhone dark screenshot flow | 1 passed |
| iPad Pro 11-inch (M4) / iPadOS 18.5 screenshot flow | 1 passed |
| Release app + widget build for device | Passed; no compiler warning/error matches in the captured release log |
| Local ZIP, plist, arm64 device binary, assets/notices and checksum inspection | Passed |
| Independent Mac inspection of the same IPA and stored checksum | Passed |
| Reset-guard mutation review | Passed: 4 of 6 focused tests remained green and the backwards-clock / reset-and-undo tests rejected the deliberately inverted guard; the runner verified exact source restoration |

Eleven unedited simulator captures are saved under `docs/screenshots/tendelm/`. Light/dark cards and trackers, large-text layouts, and iPad layouts were visually inspected. Screenshot data is illustrative and does not ship in Release builds. Machine-readable package, test-summary, and REA evidence is retained under `docs/validation/tendelm-1.0.0/`; full build downloads remain in `C:\Users\naith\Downloads\Tendelm-builds`.

## Scope

Optional Today cards, independent time-since trackers, reset/undo/edit/history, version-2 JSON/CSV backups with version-1 import support, local storage, Tendelm branding and IDs, and the pinned native Thinking Orbs backup progress indicator. No public release.

Repository: `C:\Users\naith\Documents\GitHub\Tendelm`, private remote `N3moStudio/Tendelm`, branch `personal`. GitHub Desktop logged registration of this exact directory on 2026-11-05 at 01:48:51 UTC. No desktop UI automation was used.

## Verification boundary

The full unit suite includes elapsed-time boundaries, backwards clocks, reset/undo isolation, local calendar/DST contribution grids, V4-to-V5 disk migration and reopen, cascade deletion, identity conflicts, malformed import rollback, history restoration, legacy backups, JSON/CSV round trips, and actual asynchronous backup files.

The inherited `ObservationAfterFetchTests/fetchBetweenReadAndMutationDetaches` explicitly records one expected SwiftData observation issue. It is not a new ignored failure. The app resolves view records through `@Query`, and the personal UI tests check updates and persistence.

UI automation covers two-tracker creation, independent reset/undo, relaunch, detail undo, rename and another relaunch, Cards selection, taps on the habit name and contribution grid, and the new-habit form. Screenshot fixtures are DEBUG-only sample data. Light, dark, maximum accessibility text, and iPad images are reviewed separately from test assertions.

The reset-guard review experiment inverts only the backwards-clock condition in the Mac runner, requires the corresponding regression test to reject it, and restores the original bytes on exit. The IPA is built from the original source before that experiment.

The package verifier checks ZIP integrity, Tendelm name/IDs/version, app and widget arm64 Mach-O device platform, no FairPlay encryption, icon assets, license notices, supported device families, and absent provisioning profile. A SHA-256 comparison verifies the local download against the Mac runner's output.

REA independently opened the delivered IPA at the same SHA-256 and inventoried 33 files and 15 directories with zero integrity contradictions. Its Apple projection found the main app, widget extension, and two core resource bundles; path-derived roles are not runtime claims. Archive evidence is complete within ZIP central-directory entries and excludes non-entry bytes. Plist values and Mach-O platform/CPU fields were separately parsed by `Scripts/verify-personal-ipa.py`.

- REA inventory: `ev_8833bf07e7a61eee91f5943fe8a55dc2d7d7ef26e7cb0742dcd5c0e3e4fedc5d`.
- Manifest: `agm_17759e3cec14dbe6f8b01cc7a2f9f9411f3774d3726044fd928a88453b57be9e`.
- Apple projection: `ev_522fbaee996425c5756d8e28d005bdf4e87864b6d27552962035db7ebeced66d`.
- Complete retained evidence: `C:\Users\naith\Downloads\Tendelm-builds\41957168032\rea-ipa-evidence.json`; the REA session was closed after export.

## Still requires the user's device

Personal signing and installation; actual iPhone/iPad rendering, gestures, VoiceOver and haptics; notifications after locking/backgrounding; widget sharing with the chosen signer's App Group provisioning; low-power/battery behavior. These are not established by a successful Mac build or simulator run. The app uses local storage, so export before uninstalling or changing signing identity.

New personal-edition text uses English fallback; existing upstream English/French translations remain. The generated flattened icon has not been processed through Icon Composer or reviewed on a physical Home Screen.
