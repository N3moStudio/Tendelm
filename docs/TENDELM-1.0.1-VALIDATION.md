# Tendelm 1.0.1 (2)

## Changes

- New time-since trackers and trackers without resets can start in the future, including later today. The editor preserves the selected date instead of clamping it to now.
- Scheduled cards/details show a countdown. Reset becomes available automatically at the start. Visible clocks refresh from the saved timestamp; no background timer is required.
- Existing history remains valid: the original start cannot move later than the first reset.
- Appearance separates System / Light / Dark from Color palette. Palette rows have three small preview dots with an explanation. Individual habit/tracker colors remain editable.
- Every palette is available to the app and widget without a purchase mirror. Preference storage checks for an accessible App Group and uses local defaults when unavailable, preserving an earlier choice when possible.
- Bundle IDs, icon, record schema, history and backup format remain unchanged.

## Investigation

Baseline run [41965029805](https://github.com/N3moStudio/Tendelm/actions/runs/41965029805), commit `0dc9b22`, verified that selecting Classic already changed rendered habit badge pixels and every palette was selectable in the simulator. The original picker changed habit colors rather than the page background; no device-specific failure was reproduced. The old widget renderer still gated four palettes on the absent upstream purchase mirror, and suite construction alone was incorrectly treated as proof of shared-preference access.

## Verification

Successful build and simulator run: [41967866606](https://github.com/N3moStudio/Tendelm/actions/runs/41967866606), app source `d4bb1070ea7e6a9bdc144756a9c17b8563115cbc`. Later commits change workflow/review tooling and documentation only; the application, core package, widget and project trees match this tested commit.

| Check | Result |
| --- | --- |
| Full unit suite | 784 passed, 1 preexisting expected SwiftData issue, 0 unexpected failures; 785 declarations |
| iPhone 16 Pro / iOS 18.5 interactions | 9 passed: future calendar selection, edit/relaunch, automatic start, reset/undo, cards, large text, all palettes, live painted-color changes and display/palette persistence |
| iPhone dark screenshots | 1 passed |
| iPad Pro 11-inch (M4) / iPadOS 18.5 screenshots | 1 passed |
| Release arm64 app and widget | Passed; no compiler warning/error matches in the captured device build log |
| Mac and downloaded IPA inspection | Passed: ZIP integrity, IDs, version/build, device binaries, assets, attribution and checksum |
| Reset-guard mutation | Regression tests rejected the deliberately inverted guard: 3 intended failures, 5 passes; source restored |
| Countdown-boundary mutation | [41968750279](https://github.com/N3moStudio/Tendelm/actions/runs/41968750279) passed the review: the inverted scheduled/elapsed condition caused the intended boundary test to fail, with 7 other focused tests passing; exact source restoration verified |

The first integration run exposed a main-thread redraw problem when an entire tracker was wrapped in a ticking timeline. Frequent updates now stay in the clock label, using a stable schedule. A cancellable view task wakes controls at the start and stops when inactive/offscreen. The native date-picker test also exposed an inherited accessibility identifier from its disclosure container; removing the container identifier made the picker independently addressable. The final suite passes these flows without idle timeouts.

Sixteen unedited simulator images are in `docs/screenshots/tendelm-1.0.1/`. Appearance in light/dark, the future editor and scheduled card/detail, maximum accessibility text, and iPad detail were visually reviewed. These are illustrative test records, excluded from Release builds. JSON summaries and package reports are in `docs/validation/tendelm-1.0.1/`.

## Delivered artifact

- `C:\Users\naith\Downloads\Tendelm-1.0.1.ipa`, **10,251,577 bytes**; version **1.0.1**, build **2**, iOS/iPadOS **18.0+**.
- SHA-256: `53984e3f62afa4375fdfe4d272262c593e84ec91fb693e91b32e5815094bc186`. The downloaded file and final Downloads copy both match the Mac runner's checksum. A `.sha256` file is beside the IPA.
- Main ID `com.n3mostudio.tendelm`; widget `com.n3mostudio.tendelm.TendelmWidgets`; no provisioning profile, so personal signing is required.
- Local repository remains `C:\Users\naith\Documents\GitHub\Tendelm`; private remote `N3moStudio/Tendelm`, branch `personal`. No GUI automation was used.

Physical-device signing, appearance, gestures and App Group widget sharing remain outside simulator/package evidence. No public release is created.
