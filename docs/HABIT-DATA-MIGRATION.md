# Habit history migration

Research checked 2026-11-05. This is a practical selection of established habit apps, not a verified market-share ranking. Source formats can change; no user's real export was supplied. The adapters follow documented columns and synthetic fixtures. Native checks are recorded by release; real-export acceptance remains pending.

## What the local implementation accepts

In Settings → Import & export → Import from another app, choose a file or tap Paste beside **Paste history text**, review the preview, then tap Import history. Parsing happens on the device. Canceling the preview writes nothing.

### If the file picker does not work in your sideloaded copy

- **Tendelm JSON backup:** Settings → Import & export → the inline **json.site** link. Choose the backup on [json.site](https://json.site/), copy its JSON contents, tap the browser's Done button, then tap Paste beside **Paste backup text**. Review and confirm. This follows Elsepin's existing helper-and-paste flow.
- **Streaks, Habitify or simple daily CSV:** Import from another app → the inline **CSVJSON** link. Choose your CSV on [CSVJSON](https://csvjson.com/csv2json), keep its default row-array output, copy the JSON, tap Done, then Paste. Raw CSV text copied from an editor also works. Turn off Parse JSON if a cell is treated as a nested object or array.

Paste copies the file's **contents**, not a website/file link. Native PasteButton requests access only when tapped. Opening either helper does not send a backup, read the clipboard, import data, or write records. The system Safari sheet provides Done; returning leaves the user at the import screen. Third-party pages have their own policies: CSVJSON states conversion runs in the browser; that statement is not a network audit. Do not use json.site's Share feature for private backups.

The CSV helper changes the text format only. It does not add support for unsupported apps or convert a full database backup into daily history. JSON input must be an array of daily row objects with the same columns as the supported CSV. Both routes use the same status/date/identity validation, duplicate handling and confirmation. A Tendelm backup belongs in **Paste backup text**, not **Paste history text**.

| Source | Accepted format | Mapping and limits |
|---|---|---|
| Streaks | Daily CSV with `title,entry_type,entry_date`; optional `task_id,notes,quantity` and other documented columns | `completed_manually` → checkmark; `missed_manually` → unmarked day with status note; `skipped_manually` → unmarked day with skip note. `YYYYMMDD` dates. Unknown statuses, including unverified automatic/partial variants, stop the import. |
| Habitify | CSV with `Habit,Date,Status,Habit ID`; optional `Total log,Unit` | Completed → checkmark; Failed/Skipped → unmarked day with status note. Original amount/unit goes in notes. YYYY-MM-DD, YYYYMMDD, or slash-separated dates; asks month/day order when the file is ambiguous. Timestamps and unverified localized date forms are rejected. |
| Simple CSV | `habit,date,status,note` (`note` optional); optional `habit_id` | One row per habit/day; completed, failed or skipped; prefer YYYY-MM-DD. This is a manual conversion route for other spreadsheets, not automatic support for every app's export. |

These imports create daily yes/no habits. Set schedules, counter/timer targets, icons, colors and reminders afterward. Skipped days do not pause Tendelm streaks; the preview explains that totals can differ. Extra source metadata is not imported. Negative habits use the source's completed/failed meaning; check the resulting daily habit before changing its goal type.

Namespaced source IDs keep repeated imports from duplicating records, including after restoring a Tendelm backup. If IDs are absent, the source habit name is the identity: same-named source habits group together, and a later source rename creates a separate habit. This limitation appears in the preview.

Existing imported habits retain their names, colors, schedules and reminders. Existing daily records win over incoming data, even when their IDs differ. Earlier new days extend the habit's start date so that history is visible. Changed goal types stop merging rather than guessing quantities. Removing an existing day and importing that source day again can recreate it; deleted records do not have tombstones. Unrelated habits and time-since trackers remain intact. Save failures roll back this import; unfinished edits block it before mutation.

Limits: UTF-8 CSV or converted JSON row arrays, 8 MB, 50,000 rows, 500 habits, 240-character habit names and 10,000-character notes. JSON has at most 100 columns and cannot contain nested cell values. Conflicting duplicate rows, invalid/future dates, unknown statuses and malformed files reject the whole import before writing.

## Export/import landscape

| App | Export and import evidence | Route into Tendelm |
|---|---|---|
| Streaks | Task CSV and full `.streaks` JSON backups. Its own CSV importer is documented. [Export](https://streaks.app/help/export-task-data/), [CSV columns/import](https://streaks.app/help/import-data-from-other-apps/). | Settings → Manage Data → Export Data → Tasks → CSV → save to Files → Tendelm. Documented daily statuses supported by the new code. |
| Habitify | CSV for daily logs; SQLite for full backups. Also documents imports from Streaks and Productive. [Export](https://intercom.help/habitify-app/en/articles/10501738-how-to-export-data-of-habitify-account), [Streaks importer](https://intercom.help/habitify-app/en/articles/12645937-how-to-import-data-from-the-streaks-to-habitify). | Settings → Import / Export → Export as .csv → save to Files → Tendelm. Date formats still need confirmation against representative real exports. |
| HabitKit | JSON backup with habits/completions/other settings; restores its own format, replacing existing data. Does not offer foreign CSV import. [Developer help](https://habitkit.app/help/data-backup-and-sync/export-and-import-your-data). | Not accepted directly. An anonymized export is needed to establish field names, date encoding and quit-history semantics before writing a safe adapter. |
| Loop Habit Tracker (Android) | Settings → Database → Export as CSV produces a ZIP of CSV files; full backup restore is separate. [Maintainer FAQ](https://github.com/iSoron/uhabits/discussions/689). The [current exporter source](https://github.com/iSoron/uhabits/blob/dev/uhabits-core/src/commonMain/kotlin/org/isoron/uhabits/core/io/HabitsCSVExporter.kt) distinguishes computed entries, per-habit notes and combined checkmarks. | Not accepted directly. Extracting ZIPs and mapping real/manual vs computed completion values, numeric goals, and notes needs a versioned adapter. Do not treat every nonzero value as completed. Simple CSV conversion is possible for verified daily yes/no records. |
| Way of Life | Developer's Android listing advertises CSV/JSON export and backups. A general foreign-file importer was not verified. [Official listing](https://play.google.com/store/apps/details?hl=en&id=com.wayoflife.app). | Not accepted directly. Obtain a representative export, then map its day statuses and journal notes into simple CSV; automatic columns are not verified yet. |
| Quitzilla | Developer release notes advertise exporting habits and diary entries to CSV. Import support and exact reset-history columns were not established. [Official iPhone listing](https://apps.apple.com/us/app/quitzilla-quit-tracker/id1533076568). | Not accepted directly. Preserve reset timestamps and time zones in a dedicated time-since adapter after inspecting a sample. Daily checkmarks are not an equivalent substitute for reset events. |
| Productive | Habitify documents importing Productive `.sqlite` exports, with conversions/limitations. This evidence comes from the receiving app's integration documentation, not a Productive schema. [Habitify's Productive importer](https://intercom.help/habitify-app/en/articles/12645522-how-to-import-data-from-productive-to-habitify). | No direct SQLite support. A possible indirect route is Productive → Habitify → CSV → Tendelm; this route is inferred from those documented features and has not been tested end to end. It adds an account/extra app, so it is not the default recommendation. |

## Small next steps

Prioritize sanitized export examples for HabitKit and Quitzilla before more settings or a general field-mapping wizard. They would cover the visual habit grid and time-since use cases while keeping entry simple. Validate original dates, missing/skipped days, units, target direction, duplicates and backup round trips for each new adapter.

No new account, paid service, dependency or data upload is needed for the adapters implemented here.
