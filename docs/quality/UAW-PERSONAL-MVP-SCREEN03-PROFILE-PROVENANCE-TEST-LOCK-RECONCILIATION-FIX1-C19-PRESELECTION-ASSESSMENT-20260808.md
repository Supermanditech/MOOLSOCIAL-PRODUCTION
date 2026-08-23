# UAW Personal MVP Screen03 profile-provenance test-lock reconciliation — C19 preselection

Date: 8 August 2026

Ticket: `UAW-PERSONAL-MVP-SCREEN03-PROFILE-PROVENANCE-TEST-LOCK-RECONCILIATION-FIX1-C19`

Classification: `mvp_required`

State: **DISCLOSED AND FOUNDER AUTHORIZED**

## Customer outcome

Every future profile review APK retains independently verifiable candidate and
startup provenance without changing the founder-accepted Screen03 login and
OTP experience.

## Reuse and duplicate search

C19 reuses Screen03 v2 presentation, interaction contract, three native Flutter
owners, provider asset, behavior/copy/fitment tests and all three golden masters.
It also reuses the existing platform configuration test and permanent regression
gates for profile runtime markers. The repository contains no Screen03 v3 or
other successor acceptance that locks the current mandatory provenance test.

An exact twelve-owner audit found one and only one mismatch against v2:
`apps/mobile/test/platform_configuration_test.dart` changed from
`490721029d88301e42dc593526618b4f94198ab586c1e55d709cae12776123bc` to
`deffe5cfd7cd7c1432d6057e5c045a1569dc3f71fbd5f9d8ef26251e984a68ca`.
The delta is a single test asserting the exact profile candidate and startup
markers required by `REG-20260806-006-PROFILE-RUNTIME-MARKER-SUPPRESSED`.
The other eleven owners remain exact.

## Smallest complete work

- preserve Screen03 v1 and v2 byte-exact and mark v2 superseded only in the
  manifest;
- add a four-file, text-only native-production Screen03 v3 acceptance package
  with the unchanged interaction/presentation contract;
- lock the same twelve production owners, changing only the platform test hash;
- add a focused C19 lineage, inventory, one-active-version and owner-hash gate;
- run Screen03 behavior/golden/fitment/copy tests, platform configuration tests,
  permanent profile-marker regression gates and the global approved-UI gate;
- resume C18C only after C19 passes.

Implementation disposition: `reuse`, `configuration`, `test_only_acceptance`,
`new_necessary_work`.

No runtime source, screen, route, copy, feature, backend owner, provider or
persistent state is created. Timeline impact is 0.5 day and remains inside the
60–75 day delivery lock. Build and install remain closed.
