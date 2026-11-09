# Palette and Recently Deleted follow-up

User scope, November 8: remove the Surface setting and the duplicate Classic/Vivid
choices, make the remaining palettes visibly different, keep native transparent
chrome, and add swipe actions and hold-and-drag selection to Recently Deleted.

## Changes and preservation

- Tendelm keeps its original cream/ink/sage values. Muted uses dusty mauve and grey;
  Autumn uses terracotta, amber and olive; Sage uses green surfaces and accents.
  Existing semantic colors now read the palette from the existing environment via
  a UIKit trait bridge. No process-global mutable palette or `.id(theme)` remount.
- Classic/Vivid raw values still decode and read as Tendelm for rendering. Reading
  does not rewrite stored preferences. Individual habit color slots, identities,
  history and all System/Light/Dark choices remain intact; widgets read the same
  effective palette.
- The Surface section and identity-card suffix are gone. The retired key is
  ignored. Native navigation/tab materials and selection animations remain; no
  new glass layer or custom animation was added.
- Recently Deleted keeps its store, 30-day retention, inline actions, bulk actions,
  selected-ID reconciliation, error handling and captured-ID deletion alerts.
  A trailing swipe exposes Restore and Delete. Restore acts immediately; Delete
  opens the same confirmation. Full-swipe action is disabled.
- In Select mode, holding a row for 0.35 seconds begins a selection sweep. Moving
  across visible rows selects the whole range, including rows skipped by touch
  samples. Starting on a selected row deselects. Reversing direction restores the
  starting selection outside the current range. Tap and Select All remain
  available for accessibility; ordinary scrolling does not require a hold.

The feature map was updated before edits. No database, backup format, app identity,
permission flow, importer/exporter or delivered IPA was changed.

## Evidence

Initial native run `6af164a024e1ec237557ca87` compiled source `c4b5c3a` and ran
845 logical unit tests: 843 passed, one pre-existing expected SwiftData observation
issue, and one failure. The new selection and semantic-palette tests passed.
The failure caught Autumn's dark gold outside the sRGB gamut; its lightness was
corrected from 0.86 to 0.84 in `6e13dbd`. The UI stages did not run after that unit
failure. The earlier `27871c2` run was cancelled after a stale test-fixture reference
to the removed Surface type was found; `c4b5c3a` fixed that reference.

Run `6af1668024e1ec237557cb02` passed 844 unit tests plus the known expected issue. Its UI phase passed 12 checks and found four failures: the bridged theme key fell back to UIKit defaults, so palette renders stayed unchanged; the SwiftUI sequenced hold/drag stopped at its anchor. Swipe restore/delete and its cancellation passed. The fix restores the original SwiftUI habit environment, installs the color trait on the owning window, and uses a continuous native long-press recognizer. A separate fixture-based gesture check now runs early, alongside palette pixel checks. Empty calendar cells also get a dedicated semantic fill so tinted cards cannot make unscheduled days outweigh scored cells.

Final native validation is in progress. Results and inspected screenshots will be
recorded here. Simulator checks cannot establish physical-device gesture timing,
VoiceOver experience, sideload installation or battery/performance acceptance.
