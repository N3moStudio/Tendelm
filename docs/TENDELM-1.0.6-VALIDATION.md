# Tendelm 1.0.6 (7)

Status: built privately, inspected and delivered on 7 November 2026 Pacific (8 November UTC). Only Tendelm-1.0.6.ipa was placed in the delivery folder. Tendelm-1.0.5.ipa was recycled after the replacement matched the inspected artifact; other projects' files were verified unchanged.

## Source and native evidence

- Package commit: 6d66826aae7fac5b1f02244e96d540413dbe9fea, personal branch. GitLab project 88567868 was confirmed private through its authenticated API.
- Native-test baseline: d205ded203d60346d0efa2b10048f1148b6b7e98, successful simulator run 6aeff00124e1ec2375576207. It passed 841 unit tests with one pre-existing expected SwiftData observation issue, plus all 17 UI checks (14 light iPhone, 1 dark iPhone, 2 iPad). Light/dark, maximum-text and iPad layouts were inspected. See [settings adoption](SETTINGS-ADOPTION.md).
- Scripts/verify-settings-baseline.py verified identical app and test source. Only the exact version/build metadata change from 1.0.5 (6), build tooling and documentation are allowed. Five negative checks rejected changes to app source, UI tests, entitlements, unrelated project settings and an unverified baseline.
- Package workflow: tendelm-validated-ipa, Codemagic run 6af019ac24e1ec237557698b. It independently repeated the source-equivalence check, compiled the Release iOS device app and inspected the IPA. Native exit code 0; evidence collection complete. Xcode 26.6 (17F113), Swift 6.3.3; no device-build warnings. Previously passed simulator checks were reused, not rerun.

## Package and delivery

Local and CI inspection both passed: version 1.0.6, build 7, minimum iOS 18.0, 10,779,013 bytes, device arm64 app and widget executables, unchanged com.n3mostudio.tendelm identifiers, matching widget version, retained Native Settings Kit and upstream notices, intact archive, no test bundles or embedded provisioning profile. The delivered file matched the inspected CI artifact internally.

Delivered: C:/Users/naith/Desktop/ipa/My Projects (N3mo Studio)/Tendelm-1.0.6.ipa. This is the personal-sideload package and needs signing through the user's usual installer. No public release, browser takeover or change to another app was made.

Machine-readable evidence is retained under [validation/tendelm-1.0.6](validation/tendelm-1.0.6). Full build logs and original downloaded artifacts remain under .build/artifacts/ipa-1.0.6-6af019ac24e1ec237557698b. No reports, ZIPs or sidecars were placed in the delivery folder.

## Still requiring device acceptance

Signed installation/update, real-phone navigation and gestures, VoiceOver speech, system permission/provider round trips, widget entitlements, battery and performance remain unverified. Native compilation, simulator checks and package inspection do not establish those outcomes. All existing data identifiers, saved defaults and backup formats were retained.
