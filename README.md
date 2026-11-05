# Tendelm

A calm personal habit and time-since tracker for iPhone and iPad. Built from [Kadō](https://github.com/scastiel/kado), with original attribution preserved.

![Tendelm icon](branding/tendelm/Tendelm-01.png)

## Everyday use

- **Today:** keep the familiar list, or choose **View → Cards** for a compact contribution calendar on each habit. Existing quick-log controls remain.
- **Time since:** tap **+**, name a tracker, and start. Each tracker counts independently. **Log a reset** records an occurrence; **Undo** restores the previous run. Open a tracker for seconds, quiet history, editing, and deletion.
- **Settings → Data:** export or restore JSON and CSV, including all time-since trackers. Original Kadō version-1 backups remain readable. Version-2 exports require Tendelm or another importer supporting that format.
- No account, onboarding, analytics, or subscription. Original source palettes are available locally. Thinking Orbs appears only while a real backup is being prepared, with reduced-motion and low-power support.

## Personal build

Version 1.0.0 (1) is built. See [validation and artifact evidence](docs/TENDELM-VALIDATION.md) and [actual simulator screenshots](docs/screenshots/tendelm). The delivered IPA is `C:\Users\naith\Downloads\Tendelm-1.0.0.ipa` and requires personal signing.

- Local repository: `C:\Users\naith\Documents\GitHub\Tendelm`
- Project: `Tendelm.xcodeproj`, scheme `Tendelm`; core module `Packages/TendelmCore`.
- Bundle ID: `com.n3mostudio.tendelm`; widget: `com.n3mostudio.tendelm.TendelmWidgets`.
- Minimum system: iOS / iPadOS 18. Build on a Mac with Xcode 26.3 or later.
- Private CI workflow: `.github/workflows/personal-build.yml`. It runs tests, captures simulator screenshots, and packages an unsigned arm64 IPA for personal signing.
- Storage is local. This fork cannot use the original developer's iCloud container. Export before uninstalling or changing signing identities. Widget sharing depends on the signing method preserving a provisioned App Group.

## Credits and identity

Tendelm means tending something steadily, with elm as its botanical anchor. The name and icon are for this personal edition, not a claim of commercial trademark clearance. The whole icon was generated with the built-in image tool, then mechanically sized for the existing Xcode asset catalog. Icon Composer and physical-device appearance have not been validated.

Kadō © 2026 Sébastien Castiel, MIT. ThinkingOrbsKit © 2026 Jakub Antalik, MIT, pinned to `54722cc9a3dcb167037f7d449d6cca4d174e9eb5`. Full notices are in `LICENSE` and `Tendelm/Resources/OpenSourceNotices.txt`, also accessible in Settings → Credits.

The inherited English/French translations are retained; new personal-edition strings currently use English fallback. Historical product and design documents under `docs/` describe upstream Kadō unless identified as Tendelm work. They are not claims about this build.
