# BUY-FV2 R45 Saved, quantity and Cart motion handoff

## Decision state

Grouped owners `BUY-FV2-076`, `101`, `119`–`121`, `126`, `128`, `130`,
`132` and `133` are **TECHNICALLY/DEVICE QUALIFIED AND FOUNDER APPROVED ON
THE CUMULATIVE R55.4 OPPO BINARY — 2 AUGUST 2026**.

Founder disposition:
`artifacts/quality/buy-motion-founder-decisions-20260802-88`.

- Final candidate: `BUY-R45-SAVED-QUANTITY-CART-MOTION-FIX4`
- Profile version: `1.0.0-r45` (`2026080110`)
- Target: production `lib/main.dart`
- Branch: `remediation/prototype-conformance-2026-07-20`
- HEAD: `f1ac83dea2047f40b39d772696bd0d1224edce8e`
- Candidate/final OPPO SHA-256:
  `BAAB43F28EF6C44B82ABA757D6396BE3B71502200786AD875E7B2D37107C997B`
- APK bytes: `133001393`
- Prebuild/post-qualification source fingerprint:
  `C45E708CB2D13F7D63151312B437443EC410914C63F1D0020D6E2E346A596140`
- Source files: 1,931 under `apps/mobile/lib` and `apps/mobile/test`

## Implemented outcome

- Saved toolbar and product bookmarks settle finitely inside their existing
  fixed owners.
- Catalogue, product-detail and Cart quantities animate only the current real
  value; Shop quantity, Wholesale MOQ and Medicine limits remain session-owned.
- Mini-Cart acknowledgement/total and Cart header, line quantity/total and
  payable values settle finitely without fake loading or delayed arithmetic.
- Shared transitions are event-driven, non-repeating and resolve to zero under
  `MediaQuery.disableAnimations`.
- Pointer and accessibility activation share one handler at the Saved filter
  and mini-Cart. Catalogue steppers expose independent product-specific
  decrease/increase actions without changing geometry.
- Brand schema 6 gates the exact owners and uses only navy, saffron, white and
  green tokens. Coupons/offers, routes, backend meaning and product facts are
  unchanged.

## Candidate audit

- FIX1 is retained as nonqualifying: OPPO found the Saved filter label but no
  accessibility tap action.
- The first FIX2 package is retained as rejected build contamination. Its
  163,598,984-byte APK contained 30,597,591 bytes of orphaned incremental ZIP
  residue; all 709 live entry sizes were unchanged. No source or dependency
  growth occurred.
- Compact FIX2 is retained as nonqualifying: OPPO found the mini-Cart label but
  no accessibility tap action.
- FIX3 repaired mini-Cart activation and is retained as nonqualifying: the
  catalogue product card still merged quantity actions.
- FIX4 is the sole qualification candidate. Saved, mini-Cart and catalogue
  decrease/increase nodes are enabled, focusable and clickable on OPPO.

## Qualification

- Final Flutter analysis: clean.
- Focused motion/semantics contracts: 5/5 passed.
- Six deterministic start/mid/end/reduced-motion goldens: passed.
- Complete motion/session/Cart relevance/screen integration: 120/120 passed.
- Buy regression 1: 167/167 passed, four intentional captures skipped.
- Buy regression 2: 167/167 passed, four intentional captures skipped.
- Passing gates: schema-6 brand integrity; 25-file founder-FINAL Buy
  reference; 154 interaction routes; user-facing copy; live read-only
  nine-state HTML copy; backend boundary/self-test; data-egress
  boundary/self-test.
- The initial HTML attempt is retained as an environmental failure because its
  required local server was absent. It passed after the approved screenbook was
  served read-only; no screenbook file changed.
- Prebuild and final app/test manifests are byte-identical.

## OPPO replay and performance

The checksum-matched OPPO CPH2375 replay covers Saved on/off/on and add/
increase/decrease in Shop, Wholesale and Medicine. Shop settles `1 → 2 → 1`,
Wholesale respects MOQ `2 → 3 → 2`, and Medicine settles `1 → 2 → 1`.
The real mixed Cart settles `₹1,225 → ₹1,262 → ₹1,225`; its four products and
₹1,225 total survive HOME/resume with a 186 ms hot bring-to-front.

Accessibility exposes independent clickable Saved, save/remove, catalogue
decrease/increase, mini-Cart, Cart decrease/increase and Review order owners.
The app-specific log contains zero FlutterError, RenderFlex, fatal, unhandled,
lost-connection or native-fatal matches.

The cleared VM trace spans 6.075163 seconds with 21,418 events, 36 engine
pointer dispatches and 187 joined Dart frames. Frame p95 is 17.334 ms; three
frames exceed 33 ms, none exceeds 100 ms, maximum is 91.669 ms and there are
no shader/compile events. The VM-capture boundary frame is retained as
profiler/ADB contamination. Android `screenrecord` remains unavailable; the
earlier immutable host `scrcpy` crash remains the recorder boundary.

## Protected boundary

Screen 01 remains at the exact R42.1 pending-logo hash
`839073deb006abf663b10cad1a0e2e789d120aa7a912d3a1b02dd60440f0a2bc`.
Protected Social remains the exact 130-file pending-logo inventory. The Buy
protected hash advances from the authorized R44 value
`32497c5c791a7380e4afeabdca2751a70788c45b4ef4516f4f16cbaee2e47b38`
to `19c7eb4f74bda12f3288e30bbd59daa9069620488e14543a02b8d51094bc86c9`
only through the scoped R45 runtime owners. No protected baseline was replaced.

The separate global MoolSocial wordmark/logo ticket remains founder-rejected
and pending; R45 does not alter or claim acceptance for it.

## Evidence and founder review

Evidence root:
`artifacts/quality/buy-saved-quantity-cart-motion-r45-20260801-55`.

Review the six code-native frames `20`–`25` and physical FIX4 Shop, Wholesale,
Medicine and mixed-Cart frames `56`–`67`. Tests alone were not founder
acceptance; the founder subsequently accepted the restrained Saved/value/Cart
transitions while observing the cumulative R55.4 binary. No commit, push,
deploy, publish, merge, branch switch or whole-tree protected-baseline
replacement occurred.

Next safe approved owner: grouped Coupons and Offers motion under
`BUY-FV2-076`, `122`, `127`, `129`, `131`, `134`.
