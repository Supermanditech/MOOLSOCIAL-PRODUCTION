# BUY-FV2 R49 route-continuity handoff

Date: 1 August 2026

State: **R49.1 FIX2 TECHNICALLY AND DEVICE QUALIFIED — FOUNDER REVIEW
PENDING**

Ticket: `BUY-FV2-138`. Candidate:
`BUY-R49-ROUTE-CONTINUITY-FIX2`.

## Exact candidate

- Profile: `1.0.0-r49.1` (`2026080115`), production `lib/main.dart`
- APK size: 133,017,785 bytes
- Candidate and final OPPO-pull SHA-256:
  `3011D9C67B7637B2116CEE55FEAAF9CBEB0170A4BAC364FCC347652571BA5C84`
- App/test source files: 1,953
- Prebuild and post-install source-manifest SHA-256:
  `69B4852258264E31722889A139131A0C8930BAAA6CD59EE301DF3825949A4C95`
- Branch: `remediation/prototype-conformance-2026-07-20`
- HEAD: `f1ac83dea2047f40b39d772696bd0d1224edce8e`

## Implemented boundary

Root Buy now owns Android Back and returns to the last safe non-Buy invoker,
defaulting to Social. Search and existing product/account/Cart/tracking depth
consume Back first. A deliberate Buy-to-Social action opens the existing Mool
choices state, keeping Buy visible and one tap away without adding a new
Social control or changing protected feed presentation.

The existing Journey SharedPreferences store now records the last safe ready
route. Buy destination changes explicitly update it because Shop, Wholesale,
Medicine and Orders are state inside the root Buy route. Restoration is
canonical and fail-closed: Shop/product, Wholesale, Medicine, Cart and Orders
are safe owners; checkout, authentication, external schemes, malformed paths,
unknown Buy paths and fabricated provider/order depth are not restored.

No decorative animation, layout, customer copy, commerce rule, Cart meaning,
global wordmark or backend state was added. Existing reduced-motion behavior
does not alter Back or restoration meaning.

## Automated qualification

- Seven focused route/store/real-router tests pass after the final static-gate
  correction.
- The 60-test focused integration set passes.
- Two final unchanged-source Buy regressions pass 174/174, with the same four
  intentional capture skips in each run.
- Full Flutter analysis reports no issues.
- Brand schema 9, immutable Buy reference, 154-route interaction, user-facing
  copy, nine-state live read-only HTML copy, backend boundary/self-test and
  data-egress boundary/self-test all pass.
- The app/test source manifest is byte-identical before build and after final
  install/pull.

The legacy approved-UI, Social and Buy protected-baseline gates reject only
their recorded pending-logo/current-authorized drift: Screen 01 remains
`839073deb006abf663b10cad1a0e2e789d120aa7a912d3a1b02dd60440f0a2bc`,
Social remains the 130-file pending-logo inventory, and the current Buy tree is
`814cb7653697e212972b7ce103eb44d3a176b9d636facaaa913dda2630934373`.
No protected baseline was replaced.

## Preserved rejected build evidence

The first destination-persistence candidate, the pre-interaction-gate-fix
candidate and oversized incremental ZIP-residue builds remain preserved and
were rejected before final qualification. The pre-interaction-gate-fix APK
SHA-256 is
`635625475CE8A03BF795C00AD8D0269E586961E535AEDD99758EBE095BEFEAE4`.
The final source removes ambiguous route-prefix literals by validating URI
segments structurally; this preserves runtime meaning and lets the route gate
verify every actual literal destination.

## OPPO disposition

OPPO CPH2375 (`2b3e0f71`) accepted FIX2, reports version `1.0.0-r49.1`
(`2026080115`), and the pulled installed base matches the candidate
byte-for-byte. After the founder unlocked the device, the exact binary passed
repeated root Buy Back, Shop/Wholesale/Medicine/Orders force-stop restoration,
deliberate Social departure with one-tap Buy return, Search-first and
internal-depth Back ordering, accessibility, lifecycle/resume, the final
failure scan and the exact-binary performance trace.

Evidence root:
`artifacts/quality/buy-route-continuity-r49-1-20260801-60`.

Founder review remains pending and cannot be substituted by technical/device
qualification. The separate rejected/pending global MoolSocial wordmark ticket is
unchanged. No commit, push, deploy, publish, merge, branch switch or protected-
baseline replacement occurred.

## Founder startup failure and supersession

After OPPO was unlocked, the founder opened FIX1 and observed only the native
navy launch background. A clean force-stop reproduces the same frame through
7.7 seconds while the process remains alive. PID-specific logs prove FIX1
throws `Release configuration is incomplete` before `runApp` because the
profile rebuild omitted the sanctioned device-review runtime defines.

FIX1 is rejected and retained. The unchanged-source successor is
`BUY-R49-ROUTE-CONTINUITY-FIX2`, profile `1.0.0-r49.1` (`2026080115`), under
`artifacts/quality/buy-route-continuity-r49-1-20260801-60`. FIX2 subsequently
cold-started beyond the native launch screen and passed the complete OPPO
replay recorded below.

## FIX2 permanent gate and final qualification

Before FIX2, the founder-reproduced startup regression was registered as a
mandatory machine state in `config/apk-regression-gate-state.json`. The
fail-closed checker and Buy review-build wrapper require exact branch/HEAD,
candidate, version, build mode, source manifest, all prebuild regression
evidence and the sanctioned runtime-define allowlist before Flutter can run.
The one-build authorization was consumed and the completed state is not
reusable for another APK.

FIX2 was built through that gate with only
`MOOLSOCIAL_DEVICE_REVIEW=true`, `MOOLSOCIAL_USE_EMULATORS=true` and
`MOOLSOCIAL_CANDIDATE_ID=BUY-R49-ROUTE-CONTINUITY-FIX2`. Clean cold start now
shows Flutter MoolSocial content at 700 ms and reaches Social by 2.7 seconds;
the prior pre-`runApp` exception is absent.

The installed checksum-matched binary passed all outstanding route,
restoration, lifecycle and accessibility journeys. The final failure scan has
zero matches. Its 326-frame, 11.353471-second profile trace has p95 11.754 ms,
maximum 62.749 ms, four frames over 33 ms, none over 100 ms and no
shader/compile event. The prebuild and post-device app/test source manifests
remain byte-identical.

Qualification summary:
`artifacts/quality/buy-route-continuity-r49-1-20260801-60/87-device-replay-summary.md`.
R49.1 is technically and device qualified; founder review remains pending.
