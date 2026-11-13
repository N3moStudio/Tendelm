# Tendelm settings adoption map

## November 8 follow-up (before implementation)

The user supersedes the original six-choice/surface contract below. Keep Tendelm,
Muted, Autumn and Sage; remove Classic and Vivid from the picker. Their raw values
remain decodable and render as Tendelm without rewriting preferences on read.
Keep `kado.habitTheme`, individual habit slots, widget sharing and independent
`personal.appearance`. Palettes now also drive existing semantic page, row and
accent colors through the existing environment, without recreating navigation.
Autumn becomes terracotta/amber/olive; Muted gains dusty mauve/grey surfaces.

Remove Surface controls and identity-card surface text. Ignore, but do not rewrite,
the old `personal.settingsSurface` value. Leave the native transparent navigation,
tab bars and selection effects to iOS. No new material controls or animations.

Recently Deleted keeps the same store, expiry, inline Restore/Delete actions,
captured-ID permanent-delete confirmation, errors and bulk actions. Add trailing
swipe Restore/Delete, and hold-and-drag range selection in Select mode. Selection
is transient; no gesture itself permanently deletes or restores records.

Recorded before presentation edits. Baseline b55a940; personal branch; working tree clean. SwiftUI iOS 18+, Xcode project with synchronized app/test folders. No AGENTS.md existed in this repository or its GitHub ancestors when checked; the supplied workspace instructions apply. Native Settings Kit 0.1.0 is retained under UI/NativeSettingsKit with notices and validation limits.

Integration: adapt the kit's typography, identity card, rows, tiles and surface policy into the existing Tendelm design system. The reference package is not linked, and its example models are not used. Keep paper/ink/sage branding, the six existing habit palettes, and independent System/Light/Dark. No Bloom migration or new app-wide theme layer. No feature is removed or relocated out of its existing category.

| Setting/action | Existing location → adopted location | Model/storage | Behavior to preserve |
|---|---|---|---|
| Appearance entry (also Today announcement) | Settings row → larger identity card; same destination | Existing NavigationLink and appearanceAnnouncement service | Same identifier, Back/edge-swipe; retire announcement on visit |
| System / Light / Dark | Appearance → Display, unchanged | personal.appearance / AppAppearance | Immediate persistent independent choice; default System |
| Tendelm, Classic, Muted, Vivid, Autumn, Sage | Appearance rows → selectable palette tiles | kado.habitTheme, HabitThemeDefaults shared store; six stable enum raw values | Existing effective theme and all choices remain; no save-on-read or entitlement rewrite |
| Habit/tracker individual colors | Item editors, unchanged | HabitColor / record fields | Palettes recolor slots; choices and history survive |
| Surface (new presentation option) | Appearance → Surface | New personal.settingsSurface; Solid default, Liquid Glass optional | Settings navigation treatment only; unknown raw values preserved on read; no theme/surface coupling |
| Day starts at (all 24 hours) | Day & week, unchanged | kado.dayStartHour / DayStartDefaults | Immediate persistence; native pushed list; logging semantics unchanged |
| Week starts on | Day & week, unchanged | kado.weekStart / WeekStartDefaults | System/default and every weekday retained; widget/shared calendar rules unchanged |
| Notification status and denied-state Open Settings | Notifications, unchanged | UNUserNotificationCenter, scene refresh, UIApplication settings URL | No fake toggle/prompt; habit-save permission request remains in editor; denial/status cases intact |
| Archived list, unarchive, detail and Delete | Archived habits, unchanged | SwiftData HabitRecord.archivedAt; existing handlers | Empty state, restoration, confirmation, recovery and errors unchanged |
| Recently Deleted list / 30-day expiry | Recently Deleted, unchanged | RecentlyDeletedRecord / RecentlyDeletedStore | Pruning and preserved item/reset history unchanged |
| Select/Done, select item, Select All/Deselect All | Recently Deleted, unchanged | Existing local selection UUID set | Native row controls and selection reconciliation unchanged |
| Restore single/selected, Delete permanently/selected/All | Recently Deleted, unchanged | Existing store transaction; captured UUID deletion plan | Cancel and destructive alert, rollback/errors, exact selection remain |
| Choose backup file | Import & export, unchanged | BackupSettingsContainer, backupImporter; format 2 JSON/CSV | Security-scoped read, preview, Cancel/Import, merge identities, incompatible/malformed errors |
| Paste backup text and json.site | Import & export, unchanged | Native PasteButton; same importer; ImportHelperBrowser | No clipboard polling/upload-on-return; Safari Done returns; stable container owns sheets |
| Export JSON / CSV | Import & export, unchanged | backupExporter, lastExportAt; format 2/CSV schemas | Share/cancel, exportTask cancellation, progress, disabled states and failure alerts |
| What's in a backup? | Import & export, unchanged | DisclosureGroup explanatory content | Includes archive/history; excludes recovery/appearance; merge explanation retained |
| External file/paste, CSVJSON helper | Import & export → Import from another app, unchanged | ExternalImportView, ExternalHabitImporter and readTask | Real file/paste read, progress, cancellation, validation, date-order ambiguity choices |
| External preview / habit disclosure / Import / Cancel / Help | Same external import page | ExternalHabitImport + summary, existing commit/cancel handlers | Existing-data merge rules, quantity/skipped-day warnings, repeat-import checks and errors |
| Updates/restores explanation and Erase all data | Privacy & reset, unchanged | eraseAllTendelmData environment action, AppDataReset | Explicit Cancel/Erase alert; clears regular/demo/recovery/preferences; errors; Files/permissions exclusions |
| Project & feedback, Credits | About Tendelm, unchanged | Existing URL and bundled OpenSourceNotices | Link and readable notices unchanged; add kit notices without removing attribution |
| Dev mode toggle and first-use confirmation | Advanced, unchanged | kado.devMode, kado.devMode.hasConfirmed / DevModeController | Confirm/Cancel, separate demo store, safe return to production; no theme-triggered store swap |
| App icon alternatives / apply errors; supporter purchase/restore/retry; tips; sync status | Retained source-only components, not exposed in current personal Settings baseline | AppIconDefaults/applier, supporterPack, tipJarStore, cloudAccountStatus | Do not delete, newly expose, fake, gate differently or change service behavior as part of styling |

Compatibility: no store schema, IDs, bundle/App Group IDs, backup fields, notification handler, existing preference key/default, tab owner or navigation owner changes. The new surface key is covered by the existing personal.* full-reset policy; appearance remains excluded from backups. No .id(theme), nested navigation owner, or global appearance proxy is added.

Validation plan: portable kit checks, Swift syntax, native simulator-only compilation/tests where available, real screenshots in light/dark/accessibility/iPad, theme/surface persistence and stable navigation, existing paste and recovery flows. Existing shipped IPA remains 1.0.5; no IPA build or release is authorized for this adoption. Evidence and limitations are recorded in [SETTINGS-ADOPTION.md](SETTINGS-ADOPTION.md): final native compilation passed, 841 unit tests plus 1 existing expected issue, 17 UI checks passed, and light/dark/maximum-text/iPad screenshots were inspected. Physical-device and other untested checks are listed separately.

## November 12: independent app and habit colors

Before edits: Display remains personal.appearance. Habit colors retain kado.habitTheme. Add personal.appPalette for an independent overall palette above Habit colors; absent value inherits the existing palette without rewriting it. Surface remains absent. Existing storage, backup format, navigation and native materials remain unchanged.

## November 12: always-on native glass

No Solid or Liquid Glass picker. Ignore legacy surface preferences. On iOS 26+, leave navigation and tabs entirely under system Liquid Glass styling, without legacy UIKit appearance overrides; the floating Undo control uses the native glass button style. Older systems retain native material fallback. System accessibility preferences remain respected. Theme colors, content readability and all actions remain intact.
