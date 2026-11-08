# Tendelm settings and appearance

For appearance/settings work, read UI/NativeSettingsKit/DESIGN.md and ADOPTION.md, plus docs/SETTINGS-FEATURE-MAP.md. Preserve settings, storage, backups, permissions, confirmations, errors and cancellation; update the map before moving controls.

Use compact rounded presentation, related native rows, the larger appearance card and native Back/edge-swipe. Adapt patterns into Tendelm's existing paper/ink/sage design system; the vendored kit is a reference, not a second runtime theme system. Keep all existing habit palettes and System/Light/Dark independent.

Native compilation and screenshots are separate from portable checks. Do not run Scripts/build-personal.sh or the tendelm-ipa workflow when only styling/validation is requested: they package an IPA. Use simulator-only checks. Do not package/publish or change another app without an explicit request. Preserve the delivered IPA until a replacement is explicitly requested and verified.

Delegate only a bounded supporting task when it saves effort; the lead integrates and verifies. Do not send source or credentials to external AI services.
