# BUY-FV2 R47 Product media, title and selection depth handoff

## Decision state

Grouped owners `BUY-FV2-079`, `093` and `095` are **TECHNICALLY AND DEVICE
QUALIFIED AND FOUNDER APPROVED ON THE CUMULATIVE R55.4 OPPO BINARY — 2
AUGUST 2026**.

Founder disposition:
`artifacts/quality/buy-motion-founder-decisions-20260802-88`.

- Final candidate: `BUY-R47-PRODUCT-MEDIA-TITLE-DEPTH-FIX1`
- Profile version: `1.0.0-r47` (`2026080112`)
- Target: production `lib/main.dart`
- Branch: `remediation/prototype-conformance-2026-07-20`
- HEAD: `f1ac83dea2047f40b39d772696bd0d1224edce8e`
- Candidate/final OPPO SHA-256:
  `E95EE651411703A36D021A354F881D11B3A96A8CAE9AE300D9AA8AAFFC94B30B`
- APK bytes: `133001393`
- Prebuild/post-qualification app/test manifest SHA-256:
  `CFAB84C0A6837F9A3C6F9B816D901BB08B5EA13B20617C14AE9FC706906D760B`
- Source files: 1,945 under `apps/mobile/lib` and `apps/mobile/test`

## Implemented outcome

- Featured and dense product cards opt into a finite 110 ms spatial hold cue.
  Pointer position controls a restrained perspective brand-palette highlight
  plane while truthful media remains on a safe 2D scale/translation layer.
- Transformed hit testing is disabled. Layout, product, Saved, Add, price and
  quantity owners stay fixed and the pose returns once on release/cancel.
- The real selected product gives its existing gallery one finite 240 ms depth
  reveal and its current brand/title/variant/pack cluster one finite incoming
  reveal keyed by product identity.
- No media, gallery page, pack, seller, availability, live-data or product
  choice was invented. Exact/category media semantics and the deterministic
  MoolSocial media resolver remain unchanged.
- R36 depth remains unchanged for Orders/promotions and other non-product
  consumers. R45 quantity and R46 offer motion are not duplicated.
- Brand schema 8 owns the exact integrations, durations, fixed hit testing,
  current-product semantics, zero reduced motion and the exact four-colour
  motion palette.

## Candidate audit and qualification

- The initial whole-card perspective approach was rejected before build:
  deterministic held frames showed atlas-backed photos disappearing under the
  perspective transform. The final implementation moves perspective to an
  overlay plane; final held frames keep every real image present.
- An initial detail midpoint captured the parent route's blank transition,
  not product motion. The final harness isolates the real product owner and
  precaches approved media before capturing the 45 ms midpoint.
- Failed focused-test and image-precache harness attempts are preserved and
  distinguished from qualifying runs.
- Final Flutter analysis: clean.
- Focused motion/hit/semantics/reduced-motion contracts: 3/3 passed.
- Five deterministic held/settled/detail-mid/detail-settled/reduced-motion
  goldens: passed.
- Complete focused product/full-screen integration: 71/71 passed.
- Buy regression 1: 167/167 passed, four intentional captures skipped.
- Buy regression 2: 167/167 passed, four intentional captures skipped.
- Passing gates: schema-8 brand integrity; 25-file founder-FINAL Buy
  reference; 154 interaction routes; user-facing copy; live read-only
  nine-state HTML copy; backend boundary/self-test; data-egress
  boundary/self-test.
- Prebuild and final app/test manifests are byte-identical.

## OPPO replay and performance

The checksum-matched OPPO CPH2375 journey holds/releases the first real product
in Shop, Wholesale and Medicine. Physical held frames retain the product photo
and show the bounded spatial plane; release opens the correct 500 g Shop, 10 kg
Wholesale and Strip of 15 Medicine detail without adding anything to Cart.
Each detail retains the truthful image, title, pack, price, partner role and
vertical-owned facts. Medicine detail survives HOME/resume with a 160 ms hot
bring-to-front.

The accessibility tree retains each card as a clickable product owner and the
detail exposes the exact current product media/title; no outgoing product copy
is retained. App logs contain zero FlutterError, RenderFlex, fatal, unhandled,
lost-connection, SIGSEGV or SIGABRT matches.

The cleared exact-binary VM trace retains 4.992185 seconds with 32,641 events
and 201 paired Dart frames. Frame p95 is 6.838 ms; one frame exceeds 33 ms,
none exceeds 100 ms, maximum is 46.050 ms and there are no shader/compile
events. The finite buffer retained the later ticket-specific hold/detail
segment; earlier navigation is not misrepresented as measured.

Android `screenrecord` remains unavailable. Deterministic held/mid/settled and
physical held/settled frames are retained with the exact-binary trace.

## Protected boundary

Screen 01 remains at pending-logo hash
`839073deb006abf663b10cad1a0e2e789d120aa7a912d3a1b02dd60440f0a2bc`.
Protected Social remains the exact 130-file pending-logo inventory. The Buy
protected hash advances from R46
`8434720e0c4a3f36a1a1fe1a31d82d149e57a909b0e0a30870b941ad91bec7af`
to `7454a09b617b3293fecfce90f76bfcea4e1a51875790ddf8ac80c68a66348d12`
only through the scoped R47 product design/catalogue/detail owners. No
protected baseline was replaced.

The separate global MoolSocial wordmark/logo ticket remains founder-rejected
and pending; R47 does not alter or claim acceptance for it.

## Evidence and founder review

Evidence root:
`artifacts/quality/buy-product-media-title-depth-r47-20260801-57`.

Review code-native frames `30`–`34`, physical Shop/Wholesale/Medicine frames
`51`–`61` and profile report `65-oppo-profile-trace-analysis.md`. Tests alone
were not founder acceptance; the founder subsequently accepted the restrained
held depth plane and selected-product media/title reveal while observing the
cumulative R55.4 binary. No commit, push, deploy, publish, merge, branch switch
or whole-tree protected-baseline replacement occurred.

Next safe approved owner: query-to-results transitions under `BUY-FV2-076`,
`094`, `104`, extending only result replacement beyond accepted ticket 137.
