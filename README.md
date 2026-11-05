# Tendelm

A calm personal habit and time-since tracker for iPhone and iPad. Built from [Kadō](https://github.com/scastiel/kado), with original attribution preserved.

![Tendelm icon](branding/tendelm/Tendelm-01.png)

## Everyday use

- **Today:** keep the familiar list, or choose **View → Cards** for a compact contribution calendar on each habit. Existing quick-log controls remain.
- **Time since:** tap **+**, name a tracker, and start. Open **Start date & color** to choose a past or future date/time. Future trackers count down, then start automatically. Each tracker counts independently. In the detail screen, **Log a previous reset** records a past date/time alongside **Log a reset**. Later history stays intact; **Undo added reset** removes the event just backfilled. A reset before the initial start moves that start earlier.
- **Settings → Appearance:** choose System, Light or Dark for the display, and a palette for habit/tracker colors. The small dots preview each palette; individual colors are chosen while editing a habit or tracker.
- **Settings → Data:** export or restore JSON and CSV, including all time-since trackers. Original Kadō version-1 backups remain readable. Version-2 exports require Tendelm or another importer supporting that format.
- **Settings → Data → Import from another app:** preview Streaks/Habitify daily CSVs or simple CSV before adding habits and history. Existing daily entries are kept; duplicate imports add nothing. Skipped days and amounts are retained as notes, with differences explained before import. See [supported formats and migration research](docs/HABIT-DATA-MIGRATION.md).
- No account, onboarding, analytics, or subscription. Original source palettes are available locally. Thinking Orbs appears only during real file preparation, with reduced-motion and low-power support.

## Personal build

Version **1.0.2 (3)** was built privately on Codemagic and delivered as `C:\Users\naith\Desktop\ipa\My Projects (N3mo Studio)\Tendelm-1.0.2.ipa`. It requires personal sideload signing. See [validation evidence](docs/TENDELM-1.0.2-VALIDATION.md) and [build handoff](docs/TENDELM-1.0.2-BUILD-HANDOFF.md).

Historical [1.0.1 validation evidence](docs/TENDELM-1.0.1-VALIDATION.md), [1.0.1 simulator screenshots](docs/screenshots/tendelm-1.0.1), and [build 1 evidence](docs/TENDELM-VALIDATION.md) apply only to those versions. The older Tendelm IPA was moved to the Recycle Bin after verifying the replacement.

- Local repository: `C:\Users\naith\Documents\GitHub\Tendelm`
- Project: `Tendelm.xcodeproj`, scheme `Tendelm`; core module `Packages/TendelmCore`.
- Bundle ID: `com.n3mostudio.tendelm`; widget: `com.n3mostudio.tendelm.TendelmWidgets`.
- Minimum system: iOS / iPadOS 18. Build on a Mac with Xcode 26.3 or later.
- Current private CI workflow: `codemagic.yaml`, manually started on a Mac M2 using the private GitLab repository. It runs tests, captures simulator evidence, and packages an unsigned arm64 IPA for personal signing. The older GitHub workflow is retained.
- GitHub-independent build entry point: on a suitable Mac, run `bash Scripts/build-personal.sh` from this checkout. This script produced the verified 1.0.2 IPA; the validation record distinguishes reused passing tests from the final run.
- Storage is local. This fork cannot use the original developer's iCloud container. Export before uninstalling or changing signing identities. Widget sharing depends on the signing method preserving a provisioned App Group.

## Credits and identity

Tendelm means tending something steadily, with elm as its botanical anchor. The name and icon are for this personal edition, not a claim of commercial trademark clearance. The whole icon was generated with the built-in image tool, then mechanically sized for the existing Xcode asset catalog. Icon Composer and physical-device appearance have not been validated.

Kadō © 2026 Sébastien Castiel, MIT. ThinkingOrbsKit © 2026 Jakub Antalik, MIT, pinned to `54722cc9a3dcb167037f7d449d6cca4d174e9eb5`. Full notices are in `LICENSE` and `Tendelm/Resources/OpenSourceNotices.txt`, also accessible in Settings → Credits.

The inherited English/French translations are retained; new personal-edition strings currently use English fallback. Historical product and design documents under `docs/` describe upstream Kadō unless identified as Tendelm work. They are not claims about this build.
