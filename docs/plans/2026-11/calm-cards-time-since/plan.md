# Plan

- [x] Write focused elapsed-time, heatmap, backup, and migration tests first; observe the initial failure on Mac.
- [x] Add V5 tracker/reset storage and the small elapsed-time service; retain old habit schemas and backup reading.
- [x] Add an adaptive Cards/List picker to Today, reusing existing logging and detail actions.
- [x] Add Time since: name and Start, optional start date, independent counters, one-tap reset, undo, edit/delete, and reset history. Seconds appear only in the detail view.
- [x] Integrate local-only signing configuration, honest storage copy, and full backups.
- [x] Give the personal edition its own Tendelm name, generated icon, project/source folder names, bundle/app-group IDs, private repository, and GitHub Desktop entry beside the user's other repositories.
- [x] Run unit and UI checks; inspect simulator screenshots in light/dark, large type, and iPad.
- [x] Review the final changes, package and inspect the IPA, copy it to Downloads, and document actual validation and device-only limits in `docs/TENDELM-VALIDATION.md`.

No leaderboard, gamification, new onboarding, or required permissions. Preserve Kadō's themes and existing navigation/features. New cards are opt-in through the visible view picker; the existing List remains the default. The user requested Elsepin's Thinking Orbs: the pinned native ThinkingOrbsKit package is used only during real backup preparation, with reduced-motion and low-power handling.
