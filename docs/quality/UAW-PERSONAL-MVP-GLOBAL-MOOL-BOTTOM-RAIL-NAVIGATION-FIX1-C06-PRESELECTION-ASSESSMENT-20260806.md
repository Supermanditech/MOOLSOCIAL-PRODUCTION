# Global Mool navigation C06 preselection assessment

Ticket: `UAW-PERSONAL-MVP-GLOBAL-MOOL-BOTTOM-RAIL-NAVIGATION-FIX1-C06-PROFILE-PROVENANCE-CUMULATIVE-OPPO`
Classification: `mvp_required`
State: `PASSED_REUSE_AND_ROBUSTNESS_CHECKPOINT`

## Customer outcome

One uniquely identified profile APK contains the completed C01-C05 global Mool
navigation contract, emits truthful candidate and startup provenance in profile
mode, upgrades the currently installed OPPO app in place without deleting data,
and passes real-screen U01-U22 navigation, Back, retained-state, accessibility,
interruption, runtime-failure and checksum qualification before founder review.

## Reuse and duplicate search

The inventory covers the existing `main.dart` candidate marker,
`JourneySession` startup marker, profile-safe compile-time device-review flag,
the strict APK regression state/gate, `build-buy-device-review.ps1`, the
existing signing identity, Android badging/signature/hash tools, ADB in-place
install/pull/logcat/UIAutomator/screenshot owners, C01-C05 tests and the prior
r60.6 rejection evidence. No second build wrapper, screen, route, session,
service, backend, provider, test harness or device package is required.

Implementation dispositions: `reuse`, `configuration`,
`thin_policy_adapter`, `test_only_acceptance`.

New screens: none. New named routes: none. New backend/provider owners: none.
One unique authorized build candidate: `1.0.0-r60.7 (2026080607)`. Timeline
impact: one day maximum, within the founder-locked 60–75-day window.

## Robustness

The smallest runtime edit only makes existing candidate/startup markers visible
when `MOOLSOCIAL_DEVICE_REVIEW=true` in profile mode; normal release behavior
and customer UI remain unchanged. Pre-build qualification reuses the complete
C01-C05 double regressions, protected Buy/Social boundaries, source identity,
scope/delivery/regression/interaction/copy/security gates and the documented
pre-existing approved-lock disposition. Post-build qualification proves
signature, badging, version, built hash, installed pulled hash, retained first
install time/data, no uninstall/data clear, real OPPO screen behavior,
accessibility, interruptions and runtime logs.

## Exclusions and dependencies

No navigation redesign after C05; no new customer UI/copy/motion; no backend,
provider, message/call, payment/funds or Production action; no live external
service; no credential access; no screenbook, accepted Screen 01-03, lock,
manifest, golden or protected baseline mutation; no raw Flutter build; no
second build; no uninstall, data clear, downgrade or signature workaround; no
commit, push, deploy or promotion.

Dependencies are completed C01-C05, founder authorization, connected OPPO,
current branch/HEAD/dirty preservation, existing signing continuity, the strict
APK regression machine gate and preserved r60.4/r60.5/r60.6 evidence. The
REG-045 clean-at-HEAD Screen 01 hash mismatch remains an explicit protected
boundary disposition with pre/post zero protected-file diff; it is not
silently repaired or waived.
