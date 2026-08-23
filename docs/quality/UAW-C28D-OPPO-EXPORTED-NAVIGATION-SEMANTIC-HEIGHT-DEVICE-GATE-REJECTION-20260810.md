# C28D OPPO exported-navigation semantic-height device-gate rejection

State: `MATERIAL_DEVICE_GATE_REJECTED — NO RETRY OR MATRIX`

Candidate: `1.0.0-r60.27` / `2026081027`, SHA-256
`E4651AEADFD2A98A7617021B8DEF645BC5D428DD1593D882D278F3706FF6BD0C`.

## Passed before rejection

- C28C passed two complete identical-fingerprint host cycles: 373 passing tests,
  11 intentional skips and 22 gates per cycle.
- C28D bounds-gate self-tests passed and truthfully rejected the preserved C27F
  19-logical-pixel XML.
- Exactly one profile APK was built and exactly one in-place `adb install -r`
  returned `Success`.
- Local candidate, live installed base and pulled installed base are identical.
- Package, version, signer and preserved first-install time passed.
- The first stable screenshot visibly paints Mool, Social and all four Social
  actions before any switcher or family interaction.

## Material rejection

The first native XML gate ran at live OPPO density 320 dpi. `Open MoolSocial
main menu` exported bounds `[0,1404][108,1442]`, or 108 by 38 physical pixels.
After density normalization this is 54 by 19 logical pixels, below the required
44 by 44.

The first r60.27 hierarchy SHA-256 is
`63AAC908A9A3EA4AECB2E1AF4935616D7991B24B61C0BB3DCE0714867187B964`,
byte-identical to the preserved rejected C27F r60.26 hierarchy. Therefore the
C28B visible-overlay SystemChrome policy did not change the installed OPPO
exported navigation viewport. The exact C27F failure remains.

## Evidence and disposition

- Screenshot:
  `artifacts/quality/uaw-personal-mvp-android-navigation-oppo-qualification-fix11-c28d-r60-27-20260810-01/18-first-installed-root.png`,
  SHA-256
  `2A4090445E00329909EBBF7EF4AEA0A60DD12A39CA9F4467D412C7D60F713DC6`.
- Final and both readiness XML files share SHA-256
  `63AAC908A9A3EA4AECB2E1AF4935616D7991B24B61C0BB3DCE0714867187B964`.

The six-family/18-action matrix stopped before its first interaction. No second
build/install, uninstall, data clear, downgrade or bypass occurred. r60.27
remains installed and checksum-preserved for founder review. Founder acceptance
is not granted.
