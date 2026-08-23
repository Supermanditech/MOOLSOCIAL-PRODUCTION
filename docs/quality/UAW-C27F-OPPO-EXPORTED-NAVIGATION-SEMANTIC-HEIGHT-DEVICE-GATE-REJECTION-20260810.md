# C27F OPPO exported-navigation semantic-height device-gate rejection

State: `MATERIAL_DEVICE_GATE_REJECTED — SUCCESSOR REQUIRED`

Candidate: `1.0.0-r60.26` / `2026081026`, SHA-256
`A27200CEF659B3C1DC5F2C62ECBF6529B2F01B2036A41A0E1A7A87B186BDB1F4`.

## Passed before rejection

- C27E passed two identical-fingerprint host cycles: 369 passes, 11
  intentional skips and 21 gates per cycle.
- Exactly one profile APK was built and one in-place `adb install -r` returned
  `Success`.
- Local candidate, live installed base and pulled installed base are identical.
- Version, package, signer and preserved first-install time passed.
- The first OPPO screenshot visibly paints Mool, Social and every Social local
  action before switcher interaction.
- The visual dock occupies the intended approximately 58 logical pixels.

## Material rejection

OPPO density is 320 dpi, or 2 physical pixels per logical pixel. Android's
exported UI hierarchy reports every navigation semantic from y=1404 to y=1442:

| Semantic | Physical bounds | Logical size |
|---|---|---|
| Open MoolSocial main menu | `[0,1404][108,1442]` | 54 × 19 |
| Open Social home | `[112,1404][220,1442]` | 54 × 19 |
| YouTube Shorts, current | `[224,1404][345,1442]` | 60.5 × 19 |
| Open YouTube Videos | `[349,1404][470,1442]` | 60.5 × 19 |
| Open Feed | `[474,1404][595,1442]` | 60.5 × 19 |
| Open Create | `[599,1404][720,1442]` | 60.5 × 19 |

The required exported minimum is 44 logical pixels in both dimensions. Every
height is only 19 logical pixels, so the candidate materially fails native
accessibility/hit ownership even though Flutter host geometry and visual paint
look correct.

## Evidence and disposition

- Screenshot:
  `artifacts/quality/uaw-personal-mvp-uniform-navigation-oppo-qualification-fix10-c27f-r60-26-20260810-01/18-initial-root.png`.
- Android hierarchy:
  `artifacts/quality/uaw-personal-mvp-uniform-navigation-oppo-qualification-fix10-c27f-r60-26-20260810-01/18-initial-root.xml`.
- Stable readiness dumps with the same production owner are preserved beside
  those files.

The remaining family/action matrix stopped at this first material gate. No
second build/install, uninstall, data clear, downgrade or bypass occurred.
r60.26 remains installed and checksum-preserved for audit. Founder acceptance
is not granted; a successor must correct full-cell Android semantic ownership
and prove exported 44×44 logical bounds before another matrix.
