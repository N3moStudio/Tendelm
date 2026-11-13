# Tendelm

A calm personal habit and time-since tracker for iPhone and iPad. Built from [Kadō](https://github.com/scastiel/kado), with original attribution preserved.

![Tendelm icon](branding/tendelm/Tendelm-01.png)

## Everyday use

- **Today:** keep the familiar list, or choose **View → Cards** for a compact contribution calendar on each habit. Existing quick-log controls remain.
- **Time since:** tap **+**, name a tracker, and start. Open **Start date & color** to choose a past or future date/time. Future trackers count down, then start automatically. Each tracker counts independently. In the detail screen, **Log a previous reset** records a past date/time alongside **Log a reset**. A reset before the initial start moves that start earlier. Swipe left on a reset in **History** to reveal **Delete**. After adding or deleting a reset, a bottom-right **Undo** button reverses only that recent change for six seconds (20 with VoiceOver). A new change replaces the previous Undo; undoing, leaving the screen or backgrounding the app clears it. Other history and the start-date row stay intact.
- **Settings → Appearance:** choose System, Light or Dark for the display, and a palette for habit/tracker colors. Solid / Liquid Glass independently controls Settings bars; content stays opaque. The larger branded card opens this focused page. The small dots preview each palette; individual colors are chosen while editing a habit or tracker.
- **Settings → Import & export:** export or restore JSON and CSV, including all time-since trackers. **Paste backup text** provides the same review when file selection fails; the **json.site** link under the import rows lets you choose a JSON backup, copy its contents and return with Done. Original Kadō version-1 backups remain readable. Version-2 exports require Tendelm or another importer supporting that format.
- **Settings → Import & export → Import from another app:** preview Streaks/Habitify daily CSVs or simple CSV before adding habits and history. Choose a file, paste raw CSV, or use the **CSVJSON** link to choose a CSV and copy its JSON output back into **Paste history text**. Existing daily entries are kept; duplicate imports add nothing. Skipped days and amounts are retained as notes, with differences explained before import. See [supported formats, helper steps and migration research](docs/HABIT-DATA-MIGRATION.md).
- **Delete & recover:** hold a habit in Today or Overview, or a time-since card, and choose Delete. Settings → Recently Deleted keeps the item and its history for 30 days. Restore it, or use Select for Restore, Delete selected and Delete All. Permanent deletion asks for confirmation.
- **Start fresh:** Settings → Privacy & reset → Erase all data. This clears regular and demo records, history, Recently Deleted, app settings and reminders. Your backups saved in Files and iOS permissions remain. Updating the IPA keeps data; importing a backup merges matching records rather than clearing the store.
- No account, onboarding, analytics, or subscription. Original source palettes are available locally. Thinking Orbs appears only during real file preparation, with reduced-motion and low-power support.

## Personal build

Version **1.0.6 (7)** was built privately on Codemagic and delivered as `C:\Users\naith\Desktop\ipa\My Projects (N3mo Studio)\Tendelm-1.0.6.ipa`. It adds the Native Settings Kit appearance: compact rounded type, a larger branded card, simpler grouped rows, palette tiles and independent Solid/Liquid Glass settings bars. Existing settings, data, recovery and import/export behavior remain. Verified source-equivalence reuses 841 unit passes (plus one pre-existing expected issue) and 17 UI checks, followed by the Release device build and package inspection. It requires personal sideload signing. See [validation evidence and remaining device checks](docs/TENDELM-1.0.6-VALIDATION.md).

Historical [1.0.5 validation](docs/TENDELM-1.0.5-VALIDATION.md), [1.0.3 validation](docs/TENDELM-1.0.3-VALIDATION.md), [1.0.2 validation](docs/TENDELM-1.0.2-VALIDATION.md), [1.0.1 validation](docs/TENDELM-1.0.1-VALIDATION.md), [1.0.1 simulator screenshots](docs/screenshots/tendelm-1.0.1), and [build 1 evidence](docs/TENDELM-VALIDATION.md) apply only to those versions. The older Tendelm IPA was moved to the Recycle Bin after verifying the replacement.

- Local repository: `C:\Users\naith\Documents\GitHub\Tendelm`
- Project: `Tendelm.xcodeproj`, scheme `Tendelm`; core module `Packages/TendelmCore`.
- Bundle ID: `com.n3mostudio.tendelm`; widget: `com.n3mostudio.tendelm.TendelmWidgets`.
- Minimum system: iOS / iPadOS 18. Build on a Mac with Xcode 26.3 or later.
- Current private CI workflow: `codemagic.yaml`, manually started on a Mac M2 using the private GitLab repository. It runs tests, captures simulator evidence, and packages an unsigned arm64 IPA for personal signing. The older GitHub workflow is retained.
- GitHub-independent build entry point: on a suitable Mac, run `bash Scripts/build-personal.sh` from this checkout. The default workflow runs the complete selected checks; each validation record identifies any narrowly guarded reuse of earlier evidence.
- Storage is local. This fork cannot use the original developer's iCloud container. Export before uninstalling or changing signing identities. Widget sharing depends on the signing method preserving a provisioned App Group.

## Credits and identity

Tendelm means tending something steadily, with elm as its botanical anchor. The name and icon are for this personal edition, not a claim of commercial trademark clearance. The whole icon was generated with the built-in image tool, then mechanically sized for the existing Xcode asset catalog. Icon Composer and physical-device appearance have not been validated.

Kadō © 2026 Sébastien Castiel, MIT. ThinkingOrbsKit © 2026 Jakub Antalik, MIT, pinned to `54722cc9a3dcb167037f7d449d6cca4d174e9eb5`. Full notices are in `LICENSE` and `Tendelm/Resources/OpenSourceNotices.txt`, also accessible in Settings → About Tendelm → Credits.

The inherited English/French translations are retained; new personal-edition strings currently use English fallback. Historical product and design documents under `docs/` describe upstream Kadō unless identified as Tendelm work. They are not claims about this build.

## Licensing

Original Tendelm contributions are all rights reserved; copying, resale and reuse require permission. See [LICENSE](LICENSE). Kadō-derived code retains its [MIT license](LICENSES/Kado-MIT.txt), and existing third-party and previously granted rights remain intact. Public visibility permits viewing and GitHub forking, not unrestricted reuse of reserved contributions.
