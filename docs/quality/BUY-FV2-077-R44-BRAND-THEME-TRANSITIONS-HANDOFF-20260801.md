# BUY-FV2-077 R44 brand-theme transitions handoff

## Decision state

`BUY-FV2-077` is **TECHNICALLY AND DEVICE QUALIFIED — FOUNDER VISUAL REVIEW
PENDING**.

- Final candidate: `BUY-R44-077-BRAND-THEME-TRANSITIONS-FIX2`
- Profile version: `1.0.0-r44` (`2026080107`)
- Target: production `lib/main.dart`
- Branch: `remediation/prototype-conformance-2026-07-20`
- HEAD: `f1ac83dea2047f40b39d772696bd0d1224edce8e`
- Candidate/final OPPO SHA-256:
  `2FB0489D04A8FF2246C8E1739492E20D5094CA76A127FEA48B77148EE4973C3B`
- APK bytes: `132985009`
- Prebuild/final source fingerprint:
  `E86873212171455EB2F5C435A5E5370041520AB73A614AE040732AD20B58DBCE`
- Source files: 1,923 under `apps/mobile/lib` and `apps/mobile/test`

FIX1 and FIX2 produce the same runtime APK bytes. FIX2 exists because the first
full regression found two stale test expectations for the replaced off-palette
theme model. Only that test contract changed after FIX1; the runtime delta is
identical. The distinct FIX2 source fingerprint and rebuild provenance are
preserved.

## Implemented outcome

- Shop owns a finite navy/saffron header and saffron canvas treatment.
- Wholesale owns a finite navy/green header and green canvas treatment.
- Medicine owns a finite tricolour header and navy canvas treatment.
- Orders owns a finite navy header and tricolour canvas treatment.
- Cart/Checkout/Confirmation resolve to the saffron family; Tracking/Order
  Items resolve to green; Account/Assist resolve to navy.
- Every gradient stop and theme-motion token derives only from navy `#000080`,
  saffron `#FF9933`, white `#FFFFFF` or green `#138808`. Soft fills use alpha
  only; their RGB remains one of those four colours.
- `MoolFiniteGradientTransition` integrates at exactly two fixed owners:
  `buy-theme-canvas` and `buy-shared-header`.
- Header duration is 280 ms and canvas duration is 240 ms. Both are finite,
  state-driven and resolve to zero under `MediaQuery.disableAnimations`.
- Existing geometry, copy, routes, product facts, Cart ownership, Search/
  category motion and semantic business states remain unchanged.
- Brand schema 5 records and gates the exact vertical/screen-family mapping.

## Qualification

- Final full Flutter analysis: clean.
- R44 theme contracts: 5/5 passed, including fixed geometry, reduced motion and
  320 px/140% text.
- Six Shop/Wholesale/Medicine/Orders/Cart/Tracking visual goldens: passed.
- Focused integration: 83 tests passed.
- FIX2 focused contract repair: 8/8 passed.
- Buy regression 1: 167/167 passed, four intentional captures skipped.
- Buy regression 2: 167/167 passed, four intentional captures skipped.
- Passing gates: schema-5 brand integrity; 25-file founder-FINAL Buy reference;
  154 interaction routes; user-facing copy; immutable nine-state HTML copy;
  backend boundary/self-test; data-egress boundary/self-test.
- Source manifest is identical before the FIX2 build and after qualification.
  Candidate, installed and final OPPO-pulled APKs are byte-identical.

The HTML gate reuses the immediately preceding passing nine-state artifact.
R44 contains no HTML source and made no screenbook write; current screenbook
HEAD and hashes for `screens/09-buy.html` plus its Buy CSS/JS are recorded.

## OPPO and performance

The checksum-matched OPPO replay covers Shop, Wholesale, Medicine, Orders,
Cart and Tracking. Each route retains its own copy, products and business
meaning. Cart is reached through a real product add; Tracking is reached from
an existing order.

The accessibility trees contain exactly one standalone `MoolSocial` brand
owner on every affected screen. Header context, Cart and Tracking labels remain
route-accurate. Tracking survives HOME/resume with PID `10540` retained and a
170 ms hot activity bring-to-front.

The qualifying cleared VM trace spans 2.510 seconds with 13,201 events, 32
pointer events and 134 joined frames. Dart-frame p90 is 5.724 ms, build p90
0.847 ms, scoped-raster p90 0.419 ms, submit-inclusive raster p90 18.572 ms and
presentation p95 25.930 ms. Three frames exceed 33 ms, none exceeds 100 ms,
maximum is 42.577 ms and there are no shader/compile events. The retained
longer cold/journey trace also has no frame over 100 ms.

Final cold launch completes in 3,126 ms. FlutterError, RenderFlex, fatal,
unhandled, ANR and device-disconnection counts are zero.

## Protected boundary

Screen 01 remains at the exact R42.1 pending-logo hash
`839073deb006abf663b10cad1a0e2e789d120aa7a912d3a1b02dd60440f0a2bc`.
Protected Social remains the exact 130-file pending-logo inventory. The Buy
protected hash changes from the R42.1/DES-001 value
`05ef9af861de6b99759d8a6e538ce3a85d57d77a3b1a6e92c086ccdd6a04ea78`
to `32497c5c791a7380e4afeabdca2751a70788c45b4ef4516f4f16cbaee2e47b38`
only through the authorized R44 theme owners. No baseline was replaced.

## Evidence and recorder boundary

Evidence root:
`artifacts/quality/buy-fv2-077-theme-transitions-r44-20260801-54`.

Android `screenrecord` is not present on this OPPO; the attempt is retained.
The earlier R43 immutable evidence records the host `scrcpy` crash. The
qualifying motion set therefore combines six deterministic checksum-source
goldens, physical settled states, accessibility/lifecycle proof and the scoped
device pointer/frame trace. No duration or runtime behavior was changed to
manufacture recording evidence.

Some early ADB screenshots show a temporarily blank R42.1 wordmark tile while
later same-source screenshots show the full settled MoolSocial wordmark. The
accessibility owner remains present throughout. R44 does not modify the logo
owner and does not claim founder acceptance for `BUY-FV2-139`; review the logo
candidate separately.

## Founder review

Review the six code-native states and the physical Wholesale, Medicine,
Orders, Cart and Tracking frames. The decision is whether the finite vertical
and screen-family colour transitions are accepted. Tests are not founder
acceptance. No commit, push, deploy, publish, merge, branch switch or protected
baseline replacement occurred.
