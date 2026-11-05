# Tendelm personal edition: implementation notes

The user's scope is a calm Kadō-derived app with optional contribution cards and independent time-since trackers, under a new identity. The implementation retains the original list as default, existing habit logging/calendar/navigation, themes, and readable version-1 backups. New trackers require only a name. The only additions beyond the requested counter are undo, editable start time, history, and backup coverage.

## Decisions

- Tendelm owns `com.n3mostudio.tendelm` and `group.com.n3mostudio.tendelm`. The app, core package, widget, test targets, project, and local repository use its name. Original copyright/license and historical source documents remain attributed to Kadō.
- `Documents/GitHub/Tendelm` is beside the user's existing repositories. GitHub Desktop's CLI registered that exact location without UI automation. The remote is private; no public release is created.
- V5 adds tracker/reset entities while leaving earlier model shapes intact. A disk-backed V4-to-V5 migration test also closes and reopens the store. Explicit saves precede success feedback; failed saves roll back. Backups validate identities and history before mutation.
- Version-2 JSON/CSV includes trackers. Old version-1 files remain readable. Matching trackers restore the backup's history; unrelated trackers remain. CSV's original habit columns remain compatible and UTF-8 BOM input is accepted.
- Timers derive elapsed time from saved timestamps. No background counting service exists. List labels refresh at minute boundaries; details include seconds while visible and active. A duration day means 24 elapsed hours; the habit grid instead uses local calendar days.
- The native ThinkingOrbsKit package from Elsepin is pinned to `54722cc9a3dcb167037f7d449d6cca4d174e9eb5`. It appears only while actual backup preparation is running and pauses for Reduce Motion, Low Power Mode, inactivity, and disappearance. File encoding/writing runs off the main actor.
- Storage is local because this identity cannot use Kadō's developer-owned CloudKit container. The app states that plainly. Widget sharing depends on the personal signer's App Group support.

## Findings addressed

- SwiftData's generated public model conformance required explicitly public model classes, including those declared inside a public extension.
- Xcode 26.3's type checker stalled on chained integer arithmetic passed into `Date.addingTimeInterval`; explicit elapsed-second constants preserve the same test values.
- A SwiftData autosave-timer crash occurred while parallel test fixtures were creating and tearing down temporary stores on iOS 18.5. Test containers now disable autosave and explicitly save persistence checks. Production autosave remains unchanged. The full suite subsequently passed.
- Backup fixtures were updated for format 2 while preserving actual version-1 inputs. A pre-existing CSV BOM/header mismatch was fixed.
- Screenshot simulator configuration must boot the actual selected device: Xcode's unit-test clone can finish while that device remains shut down.
- The contribution grid is decorative for accessibility. It must not replace a habit's navigation label or expose 182 tiny elements.
- A text-field tap does not guarantee that the cursor goes to the end. The rename test now verifies the actual edited value, including after relaunch.
- XCTest's default activation point on a combined habit row selected its quick-log control. Explicit taps on the name and calendar region both pass; these test the intended navigation without relying on an ambiguous activation point.
- Simulator idleness does not guarantee that a system navigation/menu transition has finished. Screenshot capture waits briefly for the transition so a partial title or fading menu is not mistaken for the resting layout.
- The package verifier must exclude the ZIP's top-level `Payload/` directory when counting application roots. This checker correction was validated against the already-built IPA; no app-code rebuild was necessary.

The final build record belongs in `docs/TENDELM-VALIDATION.md`. Simulator and package evidence do not establish physical-device signing, notification delivery, VoiceOver interaction, widget provisioning, or battery behavior.
