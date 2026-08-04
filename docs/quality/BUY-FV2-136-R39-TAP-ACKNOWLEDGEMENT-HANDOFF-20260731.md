# BUY-FV2-136 R39.2 tap-acknowledgement handoff

Date: 31 July 2026  
Branch: `remediation/prototype-conformance-2026-07-20`  
State: `COMPLETE_FOUNDER_ACCEPTED_R39_2_TAP_ACKNOWLEDGEMENT`

## Founder decision

The founder accepted the R39.2 visual candidate on 31 July 2026. The accepted
object is the exact technically qualified and installed OPPO APK recorded
below. `BUY-FV2-136` is complete and the next sequential motion ticket may
begin.

Founder-review images:

- resting Buy frame:
  `artifacts/quality/buy-fv2-136-tap-acknowledgement-oppo-20260731-44/66-fix1-oppo-buy-ready.png`;
- held Buy product contact:
  `artifacts/quality/buy-fv2-136-tap-acknowledgement-oppo-20260731-44/67-fix1-oppo-product-held-press.png`;
- equivalent held Social contact with no cue:
  `artifacts/quality/buy-fv2-136-tap-acknowledgement-oppo-20260731-44/90-fix1-oppo-social-held-no-cue.png`.

## Accepted implementation contract

The additive app-shell layer displays one 28 logical-pixel ring at pointer
contact only while a native `/app/buy` route is active. Its navy underlay,
saffron/white/green arcs and navy centre use existing Buy colours. It changes
no resting geometry, copy, route, product/card bounds or hit target.

The layer:

- is `IgnorePointer` and `ExcludeSemantics`;
- uses the existing 110 ms press token with no timer, controller or loop;
- lets the underlying tap complete exactly once;
- ignores additional pointers while one contact is active;
- clears on up, cancel, route departure or movement beyond `kTouchSlop`;
- resolves opacity and scale transitions to `Duration.zero` under
  `MediaQuery.disableAnimations`, retaining the static held cue; and
- is absent on Social, Screens 01–03 and every non-Buy route.

The implementation is outside the protected Buy runtime tree:

- `apps/mobile/lib/ui_v2/motion/mool_buy_tap_acknowledgement.dart`;
- `apps/mobile/lib/app/moolsocial_app.dart`; and
- `apps/mobile/test/ui_v2/motion/mool_buy_tap_acknowledgement_test.dart`.

## Rejected first candidate and correction

The first profile candidate, `BUY-R39-136-TAP-ACKNOWLEDGEMENT` version
`1.0.0-r39.1` (`2026073154`), is explicitly non-qualifying. Although synthetic
route tests passed, the wrapper read `routeInformationProvider.value`, which
remained `/app/social` after the real Mool rail used `context.push('/app/buy')`.
The OPPO capture therefore contained no cue.

A real `MoolSocialApp` router test was added and reproduced the miss. R39.2
uses `routerDelegate.currentConfiguration.matches` as the live scope authority
and listens to the delegate for route changes. The new test and physical
Mool-to-Buy replay then showed the cue correctly. No R39.1 result is used as
acceptance evidence.

## Exact R39.2 candidate

- candidate ID: `BUY-R39-136-TAP-ACKNOWLEDGEMENT-FIX1`;
- build mode: Flutter profile;
- version: `1.0.0-r39.2`;
- version code: `2026073155`;
- size: `132886713` bytes;
- APK SHA-256:
  `3B4E448608A37251578EC58E7B820034AC1ABEAA4E0A3F406D0EFD9DBAE58AFA`;
- final app/test source fingerprint:
  `B8636430DF495708E02BA10E599ABB9B5A664CE377926CCABF2304AA8EE38607`.

The built candidate, `adb install` input and pulled installed `base.apk` have
the same size and SHA-256. The post-device and post-regression source manifests
also reproduce the prebuild fingerprint exactly.

## Runtime and frame evidence

The final Buy launch completed in 1,766 ms. A clean 1.2-second held contact on
the tomato product produced the intended ring at the exact input coordinate.
An equivalent held contact on Social produced no ring. The app package-PID
failure scans contain no fatal exception, ANR, Flutter error, unhandled
exception or Firebase Performance crash signature.

A 15-second warm VM-service trace captured 30 controlled stationary contacts
on non-navigating Buy space:

- joined frames: 209;
- Dart-frame p90: 0.749 ms;
- build-scope p90: 0.198 ms;
- scoped-raster p90: 0.376 ms;
- submit-inclusive raster p90: 8.118 ms;
- presentation p95: 10.694 ms;
- frames above 33 ms: 0;
- frames above 100 ms: 0;
- maximum presentation duration: 19.383 ms; and
- shader/compile events: 0.

## Deterministic and release-gate results

Seven focused widget tests pass contact/release/pass-through, drag
cancellation, non-Buy absence, route-departure clearing, zero-duration reduced
motion, semantics exclusion and real Mool-to-Buy routing. Full Flutter analysis
reports no issues.

Two complete unchanged-source Buy regressions each pass 167/167. The same four
opt-in candidate-capture generators are skipped in both runs. One earlier
invocation was host-terminated at its 60-second runner ceiling while still
passing at 120/167; it is retained as non-qualifying infrastructure evidence
and replaced by the two complete runs.

All of these gates pass:

- approved UI locks;
- app brand integrity;
- founder-FINAL Buy reference;
- interaction contracts with 154 unique routes;
- Flutter user-facing copy and nine-state read-only HTML customer copy;
- Buy backend boundary and adversarial self-test;
- Buy data-egress boundary and adversarial self-test;
- protected Social baseline, 119 files, tree
  `54851b4769c6a0087f586ce6c9325bbee1d7c790e06488eccae3a62ca953332e`;
- protected R38 Buy baseline, 31 files, tree
  `363ebe4c7342ba0118f9a7108e83fa8c2b0b3ded23332c7dd42a32849f9a5cd7`.

## Boundaries

Founder acceptance evidence is retained under
`artifacts/quality/buy-fv2-136-founder-acceptance-20260731-45`. This handoff
does not replace or expand the R38 protected baseline, close `BUY-FV2-085`,
approve later motion, connect any Buy backend/provider, authorize saved
cross-relaunch persistence, activate paid/video advertising, edit the HTML
screenbook, commit, push, deploy, publish or release.

All evidence is additive under
`artifacts/quality/buy-fv2-136-tap-acknowledgement-oppo-20260731-44`.
