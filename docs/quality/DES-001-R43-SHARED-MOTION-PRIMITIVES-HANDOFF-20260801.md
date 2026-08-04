# DES-001 R43 shared motion primitives handoff

## Decision state

`DES-001` is **TECHNICALLY/DEVICE QUALIFIED AND FOUNDER APPROVED ON THE
CUMULATIVE R55.4 OPPO BINARY — 2 AUGUST 2026**. It creates shared primitives
only. No customer, Buy, Social, launch
or protected surface uses them in this ticket.

Founder disposition:
`artifacts/quality/buy-motion-founder-decisions-20260802-88`.

- Candidate: `BUY-R43-DES001-SHARED-MOTION-PRIMITIVES-FIX1`
- Profile version: `1.0.0-r43` (`2026080106`)
- Profile target: `lib/review/mool_motion_primitives_review_main.dart`
- Production target remains: `lib/main.dart`
- Branch: `remediation/prototype-conformance-2026-07-20`
- HEAD: `f1ac83dea2047f40b39d772696bd0d1224edce8e`
- Candidate/final OPPO-pulled SHA-256:
  `A3A5F0B4FC89CC465C496C960F6109714F5ED413CE4F287FE53DED7D4D8C47AB`
- APK bytes: `103893949`
- Prebuild/final source fingerprint:
  `B3E45210299C0134030B42B830AE2AF8FA30458D6DC56D1675B78463872E5D2C`
- Source files: 1,915 under `apps/mobile/lib` and `apps/mobile/test`

## Implemented outcome

- `MoolBrand` owns the exact four identity colours and palette validator.
- `MoolBrandGradient` exposes navy, saffron, green and tricolour gradient
  states using only navy/saffron/white/green stops.
- `MoolFiniteGradientTransition` animates a fixed caller-owned decoration with
  the shared accessible duration and no controller or loop.
- `MoolFiniteTextTransition`, `MoolFiniteIconTransition` and
  `MoolFiniteStateTransition` clip finite swaps inside explicit owner sizes.
  A fade-through interval prevents outgoing/incoming content overlap.
- Outgoing visuals are excluded from semantics; one final label remains.
- `MediaQuery.disableAnimations` resolves every duration to zero and the final
  state immediately.
- The evidence-only review target mounts the production primitives directly;
  it is not routed or reachable from the customer app.
- Brand schema 4 and its gate enforce the primitive owner, four-colour stops,
  finite behavior, reduced-motion result and zero customer integrations.

## Qualification

- Full `flutter analyze --fatal-infos`: clean.
- Shared/existing motion regression: 38/38 passed.
- DES-001 focused tests: 6/6 passed.
- Initial/intermediate/settled/reduced review goldens: 4/4 passed.
- Review harness fits 320 px at 140% text without overflow.
- Buy regression 1: 167/167 passed, four opt-in captures skipped.
- Buy regression 2: 167/167 passed, four opt-in captures skipped.
- Passing gates: schema-4 brand integrity, founder-FINAL Buy reference, 154
  interaction routes, user-facing copy, nine HTML customer states, backend
  boundary/self-test and data-egress boundary/self-test.
- Source is exact before build and after qualification. Candidate and final
  OPPO pull are byte-identical.

The protected Screen 01 hash, Social 130-file inventory and R40.3 Buy runtime
hash are exactly the same pending R42.1 logo-candidate rejections. DES-001 adds
zero protected/customer integration and no new protected-gate delta.

## OPPO and performance

Initial and post-tap frames show the fixed owner and honest final state. The UI
tree contains one aggregated `Shared motion primitives review` container with
the exact final icon/text/state labels and one `Show next state` button. Home/
resume retains state and PID; hot resume completes in 101 ms.

The buffered profile tap trace spans 1.871 seconds with 5,167 events, eight
pointer events and 38 joined frames. Dart p90 is 1.911 ms, build p90 0.380 ms,
scoped raster p90 0.169 ms, submit-inclusive raster p90 9.686 ms and
presentation p95 16.162 ms. No frame exceeds 33 or 100 ms; maximum is 23.607
ms. `CreateShaderLibrary` is 0.446 ms and precompiled-code preparation is
0.011 ms. No unexplained shader/compile regression is present.

Final cold launch completes in 1,486 ms. Fatal exception, unhandled exception,
FlutterError, RenderFlex, overflow and ANR scans are all zero.

## Evidence index

Root: `artifacts/quality/shared-motion-primitives-des-001-r43-20260801-53`

- `15`–`18-code-native-*.png`: initial/intermediate/settled/reduced review.
- `24-profile-apk-identity.txt` and `28-installed-checksum-match.txt`: exact
  candidate/install identity.
- `30-oppo-device-frames` and `32-oppo-device-frames-r2`: retained raw rapid
  capture attempts, including ADB/Surface contamination.
- `33-oppo-host-paced-frames`: physical before/after tap proof.
- `34-accessibility-*`: initial/final accessibility evidence.
- `35-lifecycle-result.txt` and resumed capture: same-process lifecycle proof.
- `39-oppo-r43-des001-buffered-vm-timeline.json`: profile trace.
- `41-r43-des001-frame-summary.*` and `43-shader-and-compile-disposition.txt`:
  performance disposition.
- `44-scrcpy-*`: retained failed recorder attempts.
- `46-*`: retained denied/nonqualifying physical reduced-motion attempt.
- `47` and `48-buy-regression-*.log`: two full unchanged-source regressions.
- `49`–`61-*.log/txt`: policy and protected-delta gates.
- `62-source-manifest-after-qualification.txt` and
  `64-final-source-and-installed-stability.txt`: final source/APK identity.
- `65-final-cold-launch*`, `66-final-failure-scan.txt` and
  `67-oppo-final-settled.png`: final runtime health.

## Recorder and reduced-motion boundary

OPPO denies ADB writes to the global animation-scale settings; the attempted
change did not occur and the original values remain exact. That screenshot is
not reduced-motion evidence. Zero-duration behavior is instead proven by
focused tests and a deterministic reduced-motion golden.

Host `scrcpy` crashes with exit `-1073741819` after writing only a 48-byte
header. ADB `screencap` takes longer than the 240/360 ms primitives and some
rapid captures contain full-frame Surface contamination. These objects are
retained and excluded. The qualifying set combines device initial/final tap,
accessibility and pointer/frame trace with the exact-source code-native
intermediate golden. No duration, production widget or app setting was altered
to manufacture evidence.

## Founder review

Review the four code-native phases and the installed evidence harness. The
decision is whether these primitives are approved for later ticket-scoped use;
approval of DES-001 does not approve any particular Shop, Wholesale, Medicine,
Orders, Cart or Social presentation. `BUY-FV2-077` owns the first customer
integration and must preserve fixed geometry, meaning and protected gates.
