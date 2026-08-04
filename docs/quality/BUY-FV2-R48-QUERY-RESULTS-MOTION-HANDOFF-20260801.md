# BUY-FV2 R48 query-to-results motion handoff

Date: 1 August 2026

State: **TECHNICALLY/DEVICE QUALIFIED AND FOUNDER APPROVED ON THE CUMULATIVE
R55.4 OPPO BINARY — 2 AUGUST 2026**

Founder disposition:
`artifacts/quality/buy-motion-founder-decisions-20260802-88`.

Tickets reused without duplication: `BUY-FV2-076`, `BUY-FV2-094`,
`BUY-FV2-104`. Accepted `BUY-FV2-137` Search/category motion was not
reimplemented.

## Exact candidate

- Candidate: `BUY-R48-QUERY-RESULTS-MOTION-FIX1`
- Profile: `1.0.0-r48` (`2026080113`), production `lib/main.dart`
- APK size: 133,001,393 bytes
- APK and final OPPO-pull SHA-256:
  `3FB5D5D54105DFDBF9D28A898F3A5B4F2084A0562A984FB7047B0F4D5C6250CD`
- App/test source files: 1,952
- Prebuild and post-qualification manifest SHA-256:
  `9393A97FFA740435926C743AF7C0851F84AE1BD0265231CDF5769723CA38D8AB`
- Branch: `remediation/prototype-conformance-2026-07-20`
- HEAD: `f1ac83dea2047f40b39d772696bd0d1224edce8e`

## Implemented boundary

`BuyV2SearchResultsView` now gives only the current destination/query a finite
incoming transition. It no longer keeps an outgoing `AnimatedSwitcher` result
copy alive, so rapid typing cannot expose stale result semantics. The owner is
keyed by destination and normalized query and uses the established 240-ms
content duration.

The existing session query, vertical filtering, result order, suggestions,
product facts, empty copy, search field, keyboard/focus, clear, Back and
selection behaviors are unchanged. No wait, spinner, backend state, result,
product, entitlement or cross-vertical match was invented. The governed
palette is exactly navy, Indian saffron, white and Indian green. Reduced motion
resolves immediately to the current result.

## Deterministic and automated qualification

- Focused contracts: 3 passed, covering current-result-only replacement,
  real-screen keyboard/focus retention and zero-duration 320px/140% behavior.
- Goldens: 5 passed for ready, midpoint, settled, honest empty and reduced
  320px/140% states.
- Focused integration: 71 passed.
- Full Buy regression 1: 167 passed, 4 intentional capture skips.
- Full Buy regression 2: 167 passed, 4 intentional capture skips.
- Final Flutter analysis: no issues.
- Brand schema 9, immutable Buy reference, 154-route interaction, user-facing
  copy, nine-state live read-only HTML copy, backend boundary/self-test and
  data-egress boundary/self-test all pass.

The legacy approved-UI, Social and Buy protected-baseline gates reject only
their recorded pending-logo/current-Buy drift. No protected baseline was
replaced.

## Checksum-matched OPPO result

On OPPO CPH2375 (`2b3e0f71`):

- Shop: `tomato` exposes two real matches; replacement with `atta` exposes the
  one real wheat result and no stale tomato; `zzzzzz` exposes the honest empty
  state; explicit clear restores suggestions.
- Wholesale: `rice` exposes the real 25 kg Wholesale pack.
- Medicine: `paracetamol` exposes the real Medicine result with no Wholesale
  leakage.
- The Android accessibility tree keeps the `EditText` focused throughout
  query changes and exposes only current results.
- A HOT 169-ms resume preserves the Medicine query and current result.
- App-specific failure scan: zero FlutterError, RenderFlex, fatal,
  lost-connection, exception or SIGSEGV matches.

The cleared exact-binary VM trace contains 32,569 events and 297 paired Dart
frames across 18.479 seconds. Frame p95 is 20.757 ms; eight frames exceed
33 ms, none exceeds 100 ms, maximum is 54.631 ms and no shader/compile event
appears. This passes the established R44 frame budget.

Android `screenrecord` remains unavailable on this OPPO. Deterministic phase
frames, physical settled frames, accessibility trees and the exact-binary
trace are retained instead.

## Protected boundary and founder review

Screen 01 retains pending-logo hash
`839073deb006abf663b10cad1a0e2e789d120aa7a912d3a1b02dd60440f0a2bc`.
Protected Social remains the exact 130-file pending-logo inventory. The Buy
runtime hash advances from R47
`7454a09b617b3293fecfce90f76bfcea4e1a51875790ddf8ac80c68a66348d12`
to `91f6636d3671517956b673fb75ca5336ee3da754c306dfe9b61be0e1478533a5`
only through the scoped query-result owner. The global R50 launch wordmark was
subsequently founder approved; the separate R51 Buy-header owner remains open
for later enhancement.

Evidence root:
`artifacts/quality/buy-query-results-motion-r48-20260801-58`.

Founder visual review compared deterministic frames `11`-`15` and the
physical Shop/Wholesale/Medicine frames `31`-`43`. Tests are not founder
acceptance. The pending visual decision is whether the restrained current-
result entrance is accepted. No commit, push, deploy, publish, merge, branch
switch or protected-baseline replacement occurred.

Next safe approved owner: `BUY-FV2-138` route and Buy re-entry continuity.
