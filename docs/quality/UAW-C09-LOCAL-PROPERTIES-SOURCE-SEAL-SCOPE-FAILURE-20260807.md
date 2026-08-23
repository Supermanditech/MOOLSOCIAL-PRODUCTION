# C09 local.properties source-seal scope failure

Date: 2026-08-07
Ticket: `UAW-PERSONAL-MVP-GLOBAL-MOOL-BOTTOM-RAIL-NAVIGATION-FIX1-C09-MOOL-HOME-RESELECT-BACK-STACK-MOTION`

## Detection

The first post-build aggregate differed from the sealed pre-build aggregate.
The only runtime-root file written during the wrapper build was the ignored,
machine-generated `apps/mobile/android/local.properties`. The C09 aggregate had
incorrectly included it even though the immediately preceding C08 source
manifest explicitly excluded it.

## Exact proof

- Reconstructing `local.properties` with its exact pre-build r60.8 profile
  values produces file hash
  `9DB02C22C937813C223EDBB52D771FBF5939F472A02DE9B9254079EA54204FA4`.
- Substituting that hash reproduces the sealed 290-file aggregate exactly:
  `CD36C6CAC055D3249ED5815CC8C6F1FD616A1EC32FC8B18D8B83CC963A3E7AB5`.
- Flutter's expected r60.9 rewrite produces file hash
  `5AF54970A30B846118203D85029825F450DFF364A012054B9F2AF87AD1F0E02E`
  and the observed post-build inclusive aggregate.
- Excluding `local.properties`, the 289 authored runtime inputs have stable
  aggregate
  `7E7F9FD0C1051015DC2F28679D7685FBD221ED875182E4BE6D8771A881B2E24C`.
- No other runtime-root file has a build-time write and no second Flutter build
  occurred.

## Prevention

Source seals exclude `android/local.properties` and all other ignored
machine-generated build metadata. They separately assert its expected
candidate values after the wrapper build. Post-build drift is evaluated on the
authored aggregate, while generated metadata transitions receive an explicit
disposition. The immutable wrapper provenance remains unchanged.
