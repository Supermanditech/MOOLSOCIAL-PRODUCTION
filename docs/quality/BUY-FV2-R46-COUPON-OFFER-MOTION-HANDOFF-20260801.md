# BUY-FV2 R46 Coupons and Offers motion handoff

## Decision state

Grouped owners `BUY-FV2-076`, `122`, `127`, `129`, `131` and `134` are
**TECHNICALLY/DEVICE QUALIFIED AND FOUNDER APPROVED ON THE CUMULATIVE R55.4
OPPO BINARY — 2 AUGUST 2026**.

Founder disposition:
`artifacts/quality/buy-motion-founder-decisions-20260802-88`.

- Final candidate: `BUY-R46-COUPON-OFFER-MOTION-FIX1`
- Profile version: `1.0.0-r46` (`2026080111`)
- Target: production `lib/main.dart`
- Branch: `remediation/prototype-conformance-2026-07-20`
- HEAD: `f1ac83dea2047f40b39d772696bd0d1224edce8e`
- Candidate/final OPPO SHA-256:
  `443CA19D34048D4A976C39E2AF2C03338632592616C235D48BA7EFD5A85FEFFE`
- APK bytes: `133001393`
- Prebuild/post-qualification app/test manifest SHA-256:
  `C3301771D8543BB4B40EF34CC20E87DA73DBC64C62DFA8C62CD57594B59F625D`
- Source files: 1,938 under `apps/mobile/lib` and `apps/mobile/test`

## Implemented outcome

- Cart benefit summaries, unavailable state and provider-backed cards settle
  with finite incoming/current-state transitions inside their existing owners.
- Destination and coupon/payment selectors animate only their real selected
  treatment. Select, replacement and removal use fixed action/status geometry.
- Pointer and accessibility activation share one action. OPPO exposes the
  correct current `Select ...` or `Remove ...` label as an enabled, focusable,
  clickable node.
- Normal production remains fail-closed. The separately identified device-
  review seed inventory is compile-time review-only and total-neutral.
- No coupon saving, entitlement, compatibility, persistence, provider result
  or Cart arithmetic was invented. Shop, Wholesale and Medicine stay
  semantically independent.
- Brand schema 7 owns the exact views, adapters, durations and reduced-motion
  behavior. New visuals use only navy, Indian saffron, white and Indian green.

## Qualification

- Final Flutter analysis: clean.
- Focused motion, arithmetic and semantics contracts: 3/3 passed.
- Five deterministic start/mid/settled/replaced/reduced-motion goldens: passed.
- Complete focused integration: 90/90 passed.
- Buy regression 1: 167/167 passed, four intentional captures skipped.
- Buy regression 2: 167/167 passed, four intentional captures skipped.
- Passing gates: schema-7 brand integrity; 25-file founder-FINAL Buy
  reference; 154 interaction routes; user-facing copy; live read-only
  nine-state HTML copy; backend boundary/self-test; data-egress
  boundary/self-test.
- An initial focused test compile failure used the adapter's obsolete
  `eligibleSubtotal` test name instead of the actual `itemTotal`; it is
  preserved and repaired. A following semantics check found a current label
  without an actionable container; `container: true` and the shared handler
  repaired it before candidate build.
- Two legacy-Windows-PowerShell gate wrapper failures are retained. The same
  boundary scripts and their self-tests pass under the repository's normal
  PowerShell 7 host; this was tool-host contamination, not a source failure.
- Prebuild and final app/test manifests are byte-identical.

## OPPO replay and performance

The checksum-matched OPPO CPH2375 journey creates a real mixed Cart with four
products across Shop, Wholesale and Medicine at ₹1,225. It opens nine coupons
and nine payment offers, then exercises select/remove in all six destination/
kind families and select/replace/remove in Shop coupons. Destination subtotals
remain ₹37, ₹1,160 and ₹28. The final selected Medicine payment offer survives
HOME/resume with a 148 ms hot bring-to-front; returning to Cart retains the
unchanged ₹1,225 total.

The accessibility tree exposes three destination controls, two offer-kind
controls and three current Select/Remove actions per state. App logs contain
zero FlutterError, RenderFlex, fatal, unhandled, lost-connection, SIGSEGV or
SIGABRT matches.

The cleared exact-binary VM trace spans 14.269333 seconds with 32,522 events
and 267 paired Dart frames. Frame p95 is 28.792 ms; three frames exceed 33 ms,
none exceeds 100 ms, maximum is 96.636 ms and there are no shader/compile
events. The trace includes first route materialisation, three vertical changes,
Cart construction and rapid destination/kind/select/remove input.

Android `screenrecord` is unavailable on this OPPO. Deterministic code-native
mid-frames and physical settled frames are retained instead; no missing video
was represented as captured evidence.

## Protected boundary

Screen 01 remains at the exact pending-logo hash
`839073deb006abf663b10cad1a0e2e789d120aa7a912d3a1b02dd60440f0a2bc`.
Protected Social remains the exact 130-file pending-logo inventory. The Buy
protected hash advances from the R45 value
`19c7eb4f74bda12f3288e30bbd59daa9069620488e14543a02b8d51094bc86c9`
to `8434720e0c4a3f36a1a1fe1a31d82d149e57a909b0e0a30870b941ad91bec7af`
only through the scoped R46 benefit-view owner. No protected baseline was
replaced.

The separate global MoolSocial wordmark/logo ticket remains founder-rejected
and pending; R46 does not alter or claim acceptance for it.

## Evidence and founder review

Evidence root:
`artifacts/quality/buy-coupon-offer-motion-r46-20260801-56`.

Review code-native frames `15`–`19`, physical OPPO frames `38`–`50` and the
profile report `55-oppo-profile-trace-analysis.md`. Tests are not founder
acceptance. The review decision is whether the restrained destination/kind and
Select/Remove state transitions are visually accepted. No commit, push,
deploy, publish, merge, branch switch or protected-baseline replacement
occurred.

Next safe approved owner: product media/title/selection depth under
`BUY-FV2-079`, `093`, `095`.
