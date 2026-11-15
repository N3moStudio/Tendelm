# Tendelm daily-flow refinement — November 14, 2026

Baseline d98449b, version 1.0.9 (10), initially clean. GitHub run 43384007834 has successful package and simulator jobs, verified read-only today. That evidence predates this refinement. Older handoffs and upstream PRODUCT/ROADMAP do not define current behavior. No publication, new package or signing change authorized.

## Feature/state map before changes

| Flow | Owner and state | Preservation / review |
|---|---|---|
| Today list/cards, binary/negative/counter/timer | TodayView, TodayRow snapshots, HabitRowView, CompletionLogger | ID-based navigation and live record lookup; same logging callbacks; improve names and touch targets |
| Create/edit, schedules/reminders | NewHabitFormView and existing editors, Habit model, notification services | Same save/cancel/permission behavior; no schema changes |
| Overview, detail, calendar, history/notes | OverviewView, HabitDetailView, MatrixCell, day editor | Same historical dates, scores and streaks; no scoring changes |
| Day/week rollover | DayBoundary, App calendar/clock, DayBoundaryTests | Existing DST and non-midnight tests; no fixed 86400-second calendar arithmetic added |
| Timer logging | TimerLogSheet, Today +5m | Manual duration entry, not a running stopwatch; same validation and day boundary |
| Time since, future countdowns | TimeSinceStartGate, ElapsedTimeLabel, TimeSinceTracker | Keep scene-aware ticks and scheduled-start gate; stabilize digit widths |
| Current/previous reset, history, Undo | PreviousResetSheet, TimeSinceDetailView, TimeSinceStore, TimeSinceUndoAction | Same date ordering, exact reset inverse, 6s/20s lifecycle; add accessible history deletion action |
| Archive/recovery | HabitLifecycle, RecentlyDeletedStore/View | Same 30-day retention, bulk selection, confirmation, restore and history |
| Widgets/shortcuts | shared core, WidgetReloader, App Intents | Same callbacks and reloads, signing/App Group limitations |
| JSON/CSV/external import/paste/helpers | BackupImporter/Exporter, ExternalHabitImporter, import containers | Preview before additive merge; cancel/duplicate/date ambiguity unchanged |
| Appearance/Dev Mode | personal.appPalette, kado.habitTheme, personal.appearance, DevModeController | Preserve independent palettes, native glass, snapshot safety and store lifetime |

## Priorities

Observed in source: fixed single-line Today names, undersized quick-log targets, badge animations ignoring Reduce Motion, variable-width time digits, swipe-only reset deletion. Focus on these rather than inventing new navigation or rewards.

Needs native verification: context-menu deletion timing (previous failing run vs later successful simulator run), very large text, mixed schedules, many trackers, theme switching with open editors, background/foreground and physical-device interaction.

Optional/deferred: new palettes, calendar redesign and additional motion. Keep existing dense calendar as noninteractive overview; detailed calendar remains the editing surface.

## Implemented slice

Today keeps both list/cards and their IDs/callbacks. Names use semantic subheadline type, two lines at ordinary sizes and unrestricted wrapping at accessibility sizes; the row stacks at accessibility sizes. Binary, counter and +5m controls keep their visual symbols but gain 44-point minimum targets. Badge progress/completion respects Reduce Motion without removing normal feedback.

ElapsedTimeLabel retains its existing visibility/scene-aware TimelineView and full VoiceOver duration. A hidden two-digit reference reserves numeral width; values over two digits can still expand. No per-second layout animation was added. Reset history retains swipe deletion and now exposes the same exact-ID delete via a context menu and named accessibility action. Both reach the original save/error/widget/Undo handler.

Apple materials guidance supports keeping glass in the control/navigation layer and readable content surfaces; motion guidance supports purposeful feedback rather than continuous clock animation. References: https://developer.apple.com/design/human-interface-guidelines/materials and https://developer.apple.com/design/human-interface-guidelines/motion .

## Verification and limitations

Read-only GitHub check: baseline run 43384007834 package and simulator jobs both success. This is baseline evidence only. Current edit checks: git diff --check; source diff confirms no core persistence, score, day-boundary, backup, theme, signing or version changes. Added testHistoryContextDeleteCanUndoExactReset to exercise delete/Undo through the new menu. Existing TimeSinceUndoTests, TimeSinceTests, DayBoundaryTests (including DST cases), Dev Mode and import suites remain unchanged.

No Swift compiler, Xcode, simulator or connected iOS runtime is available on this Windows host. No current edits were compiled or natively tested, and no new screenshots were captured. The added UI regression is unrun. No source was pushed and no IPA packaged. Native follow-up: run the new context-delete test plus previous-reset/swipe-Undo tests; inspect list/cards with long names at accessibility5, small phone/iPad, all palettes and light/dark; verify touch targets do not intercept navigation; inspect 9→10, 59→0 and countdown-zero transitions; exercise VoiceOver, Reduce Motion/Transparency, editor cancellation and background/foreground. No smoothness or battery claim is made.

Principle: expand interaction space without making every visual control larger, and keep rapidly changing numbers from moving their surrounding labels.

## Native validation and delivery — 1.0.10 (11)

GitHub run 43647838569 at a61075b passed both packaging and simulator validation. Summaries: 845 unit passes, 25 UI passes (7 interactions, 13 settings, 2 dark, 3 iPad), zero failures. The new history-context-delete/Undo test ran in Interactions. The unit suite retains its pre-existing expected issue. IPA package inspection and downloaded-copy identity passed; delivered Tendelm-1.0.10.ipa to the usual project IPA folder, replacing only older Tendelm IPAs. Evidence is in .build/delivery-1010. Physical-device acceptance and visual review of the new screenshots remain separate. GitHub is updated; GitLab mirror authentication was rejected.

## 1.0.11: recorded activity and steady placement

User-approved change: Today/Overview/detail calendars show recorded slips as dark, with explicit labels; DailyValue goal scoring and streaks remain unchanged. OverviewMatrix has an opt-in activity mode, preserving widget/other callers. Today uses schedule-only sections; logging today no longer promotes unscheduled rows. Slip controls say Log a slip / Slip recorded without a success checkmark, with remove-slip VoiceOver action. Time-since actions stack, duration offers a two-line layout before its vertical accessibility fallback, and reset history groups by calendar month/year with aligned date/time. Same exact-ID deletion, start-date row, Undo and existing storage. Codebase Memory transport was unavailable this turn; focused source reads were used.
