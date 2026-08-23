# C08 durable-home cumulative OPPO preselection assessment

Date: 7 August 2026
Ticket: `UAW-PERSONAL-MVP-GLOBAL-MOOL-BOTTOM-RAIL-NAVIGATION-FIX1-C08-DURABLE-HOME-CUMULATIVE-OPPO`
Classification: `mvp_required`
State: `PASSED_REUSE_AND_ROBUSTNESS_CHECKPOINT`

## Customer outcome

One uniquely identified profile APK contains the host-qualified C07 durable Mool
home and persistent root rail plus all completed Personal navigation work,
upgrades the connected OPPO in place without deleting data, and passes the
versioned U01-U22 real-user ledger before founder review.

## Reuse and duplicate search

C08 reuses the existing C06 profile provenance markers, APK machine gate,
single-build wrapper, signing identity, source-seal format, Android
signature/badging/hash tools, ADB in-place install/pull/logcat/UIAutomator and
screenshot owners, and the complete C07 host evidence. It creates no screen,
named route, state/session, store, service, backend, provider or build pipeline.

Implementation dispositions: `reuse`, `configuration`,
`test_only_acceptance`. Candidate identity is uniquely reserved as
`1.0.0-r60.8 (2026080708)` and the timeline impact is at most one day inside
the founder-locked 60–75-day window.

## Robustness and acceptance

- Seal the exact full dirty source, branch and HEAD after all host gates.
- Require exact `MOOLSOCIAL_DEVICE_REVIEW`, emulator and candidate-id defines.
- Negative- and positive-test the machine gate before consuming one build.
- Build once through `build-buy-device-review.ps1`; raw Flutter build and a
  second build are forbidden.
- Verify signature, certificate continuity, version/badging, APK hash, source
  drift and candidate/startup runtime markers before install acceptance.
- Upgrade r60.7 in place only. Uninstall, data clear, downgrade and signature
  workaround are forbidden.
- Pull the installed APK and require byte-identical SHA-256 plus retained first
  install time.
- Replay U01-U22 from the real OPPO screen, preserving screenshot, hierarchy and
  runtime evidence. Any founder-visible blocker rejects the candidate and stops
  the replay at that first blocker.

## Exclusions

No new customer UI after C07; no backend/provider activation; no live messages,
calls, payments or funds; no credentials or Production; no screenbook, accepted
Screen 01-03, lock, manifest, golden or protected-baseline mutation; no commit,
push, deploy or promotion; no predecessor/rejection evidence overwrite.
