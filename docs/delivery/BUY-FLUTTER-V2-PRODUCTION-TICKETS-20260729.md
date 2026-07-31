# Buy Flutter V2 production tickets — 29 July 2026

## Authority and outcome

Founder FINAL authority:

`approved-references/screens/09-buy-complete/v1`

Source HTML SHA-256:

`408A095C038DD88113FBE2F901291A9BDFDCD4DC7A4C2414A27BC51B05172341`

The outcome is an isolated, native Flutter V2 Buy module that is an exact
state-by-state implementation of the approved reference. “Similar”, “inspired
by”, an HTML/WebView wrapper, a legacy-widget reskin, or a redesign is not
acceptable.

The existing Buy models, session, services, API adapters, authentication and
native configuration remain the non-UI owners. The legacy Buy presentation is
read-only until the complete V2 candidate is founder accepted.

## Ticket order

| Ticket | Scope | Exit evidence |
| --- | --- | --- |
| BUY-FV2-000 | Freeze and guard the authority | `check-buy-approved-reference.ps1` passes locally and in CI; accepted Screens 01–03 and Social baseline remain byte-stable. |
| BUY-FV2-001 | Build the parity registry | Every frozen customer state has a stable Flutter state ID, HTML route, fixture, viewport/text-scale matrix and screenshot owner. |
| BUY-FV2-002 | Create isolated native V2 package | New code exists only under `apps/mobile/lib/ui_v2/buy/` plus minimal router composition; no legacy Buy presentation file is edited or imported. |
| BUY-FV2-003 | Reuse domain and state owners | V2 adapters consume existing Buy models/session/services; no catalogue, Cart, order, address, prescription or tracking truth is duplicated in widgets. |
| BUY-FV2-004 | Implement shared Buy shell | Exact header, saved/delivery control, search, scan, live-order surface, shared edge actions, tricolour line and always-visible Shop/Wholesale/Medicine/Orders dock. |
| BUY-FV2-005 | Implement Shop catalogue | Exact category rail, search, Shop filter profile, Household Basket, product grid, fulfilment facts and inline quantity behavior. |
| BUY-FV2-006 | Implement Wholesale catalogue | Exact business context, verification boundary, Wholesale categories/search/filter, pack/MOQ/landed-price facts and quantity behavior. |
| BUY-FV2-007 | Implement Medicine catalogue | Medicine categories/search/filter, two/three-column fitment, regulatory facts, named licensed fulfiller, delivery and non-prescription Add. |
| BUY-FV2-008 | Implement product decisions | Shop, Wholesale and Medicine detail states with the exact decision hierarchy, bottom action placement and word-free return cue. |
| BUY-FV2-009 | Implement prescription flow | Saved/new prescription, one parent Rx, exact medicine-line matching, pharmacist review, linked/verified motion, approved-line Add and locked unmatched lines. |
| BUY-FV2-010 | Implement compact Cart indicator | 154×44 resting state, quantity and total; 270×44 2.6-second added-product state; no dock replacement or product-grid obstruction. |
| BUY-FV2-011 | Implement unified Cart | ₹ Total, Shop, Wholesale and Medicine scopes; single and mixed use; dense lines; independent quantities; fulfilment and legal separation; direct zero-item return. |
| BUY-FV2-012 | Implement delivery destinations | Home, Work, Third party, Other place; receiver/contact/address; current location/map/Google Maps/manual edit; WhatsApp/MoolSocial/device-share request; compact confirmation. |
| BUY-FV2-013 | Implement checkout and confirmation | Shop payment, Wholesale purchase order, Medicine-safe order, mixed order separation, exact totals, separate identifiers and failure/retry boundaries. |
| BUY-FV2-014 | Implement Orders and tracking | Active/delivered states; Shop/Wholesale/Medicine tracking; named fulfilment partner, promised time, progress and direct Track action. |
| BUY-FV2-015 | Implement reorder and recovery | One editable Reorder action; correct Add-product return; price, stock, serviceability, payment, network and delay recovery; no extra-tap dead ends. |
| BUY-FV2-016 | Implement Mool Assist | One centralized AI-assisted entry with contextual order state, in-app chat and in-app call; no repeated Get help or external dialler/email handoff. |
| BUY-FV2-017 | Implement motion, haptic, sound and accessibility | Approved subtle transitions, Cart feedback, Rx feedback, mercury-style scroll treatment where native platform permits, rate-limited deliberate-scroll detent/haptic, reduced-motion/sound compliance and semantic controls. |
| BUY-FV2-018 | Build customer-copy and route gates | Mount every reachable visible state and inspect text, hints and semantic labels; no prototype, route, fixture, source, test or internal commentary copy. |
| BUY-FV2-019 | Build exact parity tests | Matched HTML/Flutter captures at identical state, viewport and text scale; geometry, typography, colour, copy, dock, rail, card density and action-position tolerances fail CI. |
| BUY-FV2-020 | Run responsive-device matrix | 320×568 through tablets, 100%/140% and supported larger accessibility text, portrait/landscape, safe areas, display zoom, keyboard, split window and foldable states. |
| BUY-FV2-021 | Run full real-user journey matrix | Clean/retained state, process death, app switch, call, lock/unlock, offline/retry, permission/settings return, invalid input and every Shop/Wholesale/Medicine/Cart/Order interruption path. |
| BUY-FV2-022 | Build and verify physical candidate | Build from committed source, record APK SHA-256, install on OPPO, pull installed APK and prove byte identity, run affected tests and two full regressions, then request founder review. |

## Git regression gates

Every Buy V2 commit must pass:

1. `scripts/check-approved-ui-locks.ps1`
2. `scripts/check-buy-approved-reference.ps1`
3. `scripts/check-social-protected-baseline.ps1`
4. `scripts/check-brand-integrity.ps1 -Surface App`
5. `scripts/check-user-facing-copy.ps1`
6. `scripts/check-interaction-contracts.ps1`
7. `dart format --output=none --set-exit-if-changed lib test`
8. `flutter analyze --fatal-infos`
9. affected Buy V2 tests
10. complete Flutter test suite
11. Android debug build
12. iOS simulator build where the configured runner is available

Before the founder-installed-candidate gate, run the complete Flutter suite
twice from the exact committed source with independent logs. A hot-reloaded,
uncommitted or differently checksummed APK is not review evidence.

## Exact parity definition

Parity is required for each registered state, not only the default Shop screen:

- route/state ownership and back/return behavior;
- visible customer copy and semantic labels;
- screen hierarchy and component order;
- card, rail, dock, Cart and sheet geometry;
- typography family, weight, size, line height and truncation behavior;
- navy/saffron/white/green tokens and identity-line order;
- category count/order and selected-state visibility;
- product information order and bottom purchase-control placement;
- responsive column count and no-vacant-space balancing;
- Cart scope, quantity, total and order-group separation;
- motion duration, reduced-motion behavior, haptic/sound conditions;
- 44 logical-pixel effective targets, focus order and screen-reader names; and
- every interruption, failure, retry and direct-return rule.

Flutter goldens and automated screenshots are regression evidence, not new
approval authority. If native platform behavior prevents literal parity, stop
that ticket and produce a difference contract for founder decision; do not
silently improvise.

## Promotion boundary

Completion of these tickets produces a review candidate only. Dev App
Distribution, cloud trial, staging, Production, public release, participant
activation, payment activation and live pharmacy decisions remain separately
gated.

## Candidate status — 29 July 2026

The first native candidate is implemented without editing the frozen HTML or
the legacy Buy presentation:

- `BUY-FV2-000` is complete and committed. The 25-file founder-final reference
  gate is green.
- `BUY-FV2-002` through `BUY-FV2-018` have native candidate implementations
  under `apps/mobile/lib/ui_v2/buy/`, with shared state under
  `apps/mobile/lib/features/buy/buy_v2_*`.
- production `/app/buy` and historical Buy deep links resolve to V2; the
  untouched legacy presentation is available only behind
  `legacyPresentationForTestsOnly`.
- the automated V2 matrix covers 15 portrait, landscape and tablet viewports,
  140% text, the persistent six-destination dock, product decisions, mixed
  Cart, Checkout, Orders, tracking and Mool Assist.
- Shop, Wholesale and Medicine categories remain separate; mixed Cart, saved
  prescription reuse, direct empty-Cart return, delivery addresses, named
  fulfilment, promised delivery and order tracking are state-owned outside
  widgets.

The following gates remain open and must not be reported as complete:

- `BUY-FV2-001` and `BUY-FV2-019`: a screenshot-by-screenshot HTML-to-Flutter
  parity registry and automated pixel tolerances are not yet complete.
- `BUY-FV2-021`: OPPO journeys cover the primary candidate states, but the
  complete interruption/process-death/offline/permission matrix remains open.
- `BUY-FV2-022` is partially complete. Native source commit
  `f1d13569c96c6a3e4ce1069bb2fa394d5192d971` produced release-review build
  `2026072906`; its candidate and OPPO-installed APKs are byte-identical at
  SHA-256
  `0D9CD9CA1D38F41B6D4CD9CB58FFEA32F4D7F8063556E5C0A6A9BAF80D1651FD`.
  Two independently logged 47-test affected regression runs pass. Founder
  Flutter acceptance and the repository-wide legacy suite remain open.
- the repository-wide Flutter suite has unrelated/stale legacy visual-golden
  debt. Buy-owned functional, responsive, router and legacy behavior suites
  are maintained separately; the global debt must not be hidden by updating
  unrelated goldens during the Buy task.
- live commerce catalogue, payment, fulfilment, pharmacy, address-request and
  production backend activation remain separate integration/release gates.

## Founder-registered production defects

### `BUY-FV2-023` — Put Mool primary actions in the bottom rail

- Status: **IMPLEMENTED IN R17; AUTOMATED AND OPPO VERIFIED — FOUNDER
  ACCEPTANCE PENDING**
- Registered: 29 July 2026
- Founder observation: Tapping **Mool** on the OPPO opened a large modal sheet
  containing the primary action words **Social**, **Buy**, **Eat**, **Ride**,
  **Book**, **Pay** and **Work**.
- Actual result: The modal begins at approximately y=531 on the 720×1612 OPPO
  capture and presents the seven actions as oversized tiles over the current
  Buy screen.
- Expected result: These primary actions belong in the bottom rail. Tapping
  **Mool** must not replace or obscure the current screen with this large
  action popup.
- Severity: **P1 — founder-visible primary-navigation defect**
- Candidate observed: `com.moolsocial.app` version `1.0.0`
  (`versionCode 2026072912`), isolated OPPO device-review candidate.

Acceptance criteria for the later authorized implementation:

1. The primary actions are presented in the bottom rail, not in the captured
   large modal action sheet.
2. The rail preserves clear action labels, the current/selected destination and
   correct navigation for every action.
3. The rail respects the device safe area and does not obscure Buy content,
   Cart controls or purchase actions.
4. Responsive and accessibility states retain usable targets and do not
   reintroduce the modal at supported viewport or text-scale sizes.
5. Screens 01–03, the frozen Social/YouTube source and the approved Buy HTML
   screenbook remain unchanged unless the founder separately expands that
   boundary.

Evidence captured before any interaction or implementation:

- Screenshot:
  `artifacts/quality/buy-flutter-founder-tickets-oppo-20260729-04/01-oppo-current-mool-popup.png`
- Screenshot SHA-256:
  `316A6EF2FFED3BDDC37EC71F5B0A9FA859C8F97C74DFDDCDB86E4DB56F3C9A4E`
- UI hierarchy:
  `artifacts/quality/buy-flutter-founder-tickets-oppo-20260729-04/01-oppo-current-mool-popup.xml`
- UI hierarchy SHA-256:
  `F2835848BC97F18482FC7819760998673BD5AB6B0D9B1C22B518411A9A0B91C0`

Registration boundary: this entry records the founder defect and acceptance
contract only. No Flutter implementation, test, golden, route or approved
reference was changed as part of this ticket-registration pass.

### `BUY-FV2-024` — Reclaim 80–90% of the phone screen for core content

- Status: **IMPLEMENTED IN R17; AUTOMATED AND OPPO VERIFIED — FOUNDER
  ACCEPTANCE PENDING**
- Registered: 29 July 2026
- Founder observation: On the current OPPO Shop screen the customer cannot
  meaningfully see the product grid. The search control, delivery address,
  active-order surface, large text, recommendation area and Monthly home basket
  consume most of the screen. The permanently open category rail also removes
  product-grid width.
- Actual result: On the 720×1612 capture, product tiles begin only at
  approximately y=1020 and the persistent dock begins at approximately y=1369.
  Only about 22% of the physical screen remains for the visible grid before the
  dock, and the open left rail removes roughly one quarter of the grid width.
- Expected result: The responsive phone layout must prioritise the product or
  order content, with a founder target of approximately 80–90% useful content
  visibility on Android and iOS phones.
- Affected destinations: **Shop, Wholesale, Medicine and Orders**.
- Tracking: umbrella defect; destination-specific children are
  `BUY-FV2-025` through `BUY-FV2-028`.
- Severity: **P1 — cross-journey product-discovery and content-visibility
  defect**
- Candidate observed: `com.moolsocial.app` version `1.0.0`
  (`versionCode 2026072912`), isolated OPPO device-review candidate.

Founder-directed future design contract:

1. Redesign the shared phone shell so the address, search control, active-order
   state, headings, text sizing, spacing and promotional/basket surfaces use
   substantially less vertical space.
2. Preserve every necessary action and fulfilment fact while removing the vast
   empty or oversized presentation that prevents customers from seeing the
   primary content.
3. On Shop, Wholesale and Medicine, replace the permanently open left category
   rail with a compact category icon/control.
4. Tapping the category control opens the category choices and keeps them open
   until the customer selects a category.
5. After selection, the category choices close, the compact category control
   is restored, the selected category remains understandable, and the product
   grid expands to **three tiles across** on supported phone widths.
6. Apply the same compact, content-first shell principle to Orders. The
   category-selector and three-product-column requirements apply only to
   catalogue destinations.
7. Meet the 80–90% founder visibility target through responsive rules rather
   than one OPPO-specific pixel layout, covering supported Android and iOS
   phone sizes, safe areas, display scaling and accessibility text.
8. Keep the persistent bottom rail required by `BUY-FV2-023` compact and
   available without allowing it to obscure the product grid, order content or
   purchase controls.

Authority boundary for later implementation:

- This founder direction changes the currently frozen visual composition.
- Before Flutter implementation, create and present a new responsive HTML
  authority version through the approved founder `FINAL` workflow; do not
  overwrite `approved-references/screens/09-buy-complete/v1`.
- After that authority is frozen, implement it in native Flutter and add
  measurable viewport, three-column, text-scale and device-fitment tests.

Evidence captured before any interaction or implementation:

- Screenshot:
  `artifacts/quality/buy-flutter-founder-tickets-oppo-20260729-04/02-oppo-current-product-grid-visibility.png`
- Screenshot SHA-256:
  `B37AB5D678E730BCA117146586F7870A17FABA0B28E864E23527565CB0279FD2`
- UI hierarchy:
  `artifacts/quality/buy-flutter-founder-tickets-oppo-20260729-04/02-oppo-current-product-grid-visibility.xml`
- UI hierarchy SHA-256:
  `C363C73F125937EA22EF2B3147F3DD16B74B22A6781F3991A1C13D84EAC4C1EC`

Registration boundary: this entry records the founder defect, redesign
direction and acceptance contract only. No Flutter implementation, HTML,
approved reference, route, test or golden was changed as part of this
ticket-registration pass.

### `BUY-FV2-025` — Shop content-first phone layout

- Status: **IMPLEMENTED IN R17; AUTOMATED AND OPPO VERIFIED — FOUNDER
  ACCEPTANCE PENDING**
- Parent: `BUY-FV2-024`
- Destination: **Shop**
- Defect: The delivery/address surface, large search field, active-order card,
  recommendation heading/filter and Monthly home basket consume most of the
  phone height. The always-open category rail consumes product width, leaving
  only fragments of the product grid visible.
- Required outcome: Shop must meet the founder's responsive 80–90% useful
  product-grid visibility target. Its upper surfaces must become compact; its
  categories must move behind the temporary category control; and the closed
  category state must expose three product tiles across on supported phones.
- Shop-specific preservation: Household Basket, delivery context, active-order
  access, search, filtering, prices, quantities and Cart behavior remain
  available without dominating or obscuring product discovery.
- Evidence:
  `artifacts/quality/buy-flutter-founder-tickets-oppo-20260729-04/02-oppo-current-product-grid-visibility.png`
- Evidence SHA-256:
  `B37AB5D678E730BCA117146586F7870A17FABA0B28E864E23527565CB0279FD2`

### `BUY-FV2-026` — Wholesale content-first phone layout

- Status: **IMPLEMENTED IN R17; AUTOMATED AND OPPO VERIFIED — FOUNDER
  ACCEPTANCE PENDING**
- Parent: `BUY-FV2-024`
- Destination: **Wholesale**
- Defect: The business/verification surface, large search field, active-order
  card, heading/filter and always-open category rail substantially reduce the
  visible wholesale product area.
- Required outcome: Wholesale must meet the founder's responsive 80–90% useful
  product-grid visibility target. The category selector must open from a
  compact control, remain open only until selection and then restore a
  three-product-wide grid on supported phones.
- Wholesale-specific preservation: Buying-for identity, verification state,
  MOQ, pack size, landed price, delivery promise, supplier identity, quantity
  and Cart information must remain clear in the denser layout.
- Evidence:
  `artifacts/quality/buy-flutter-v2-canonical-oppo-20260729-03/14-oppo-r12-wholesale.png`
- Evidence SHA-256:
  `0DA4E55FA7C7BDB70457A72E635714EF4A7F9E0AC05AE20E2A57B8BB4350316C`

### `BUY-FV2-027` — Medicine content-first phone layout

- Status: **IMPLEMENTED IN R17; AUTOMATED AND OPPO VERIFIED — FOUNDER
  ACCEPTANCE PENDING**
- Parent: `BUY-FV2-024`
- Destination: **Medicine**
- Defect: The header, active-order surface, licensed-pharmacy banner, large
  search/upload controls, prescription shortcuts, heading/filter and
  always-open category rail leave too little phone space for medicine products.
- Required outcome: Medicine must meet the founder's responsive 80–90% useful
  product-grid visibility target. Categories must use the temporary selector,
  and its closed state must expose three medicine tiles across on supported
  phones.
- Medicine-specific preservation: Licensed fulfiller identity, prescription
  requirements, Saved Rx, pharmacist and refill access, medicine facts,
  delivery facts and regulated purchase controls must remain legible and
  reachable in the compact layout.
- Evidence:
  `artifacts/quality/buy-flutter-v2-oppo-20260729-01/25-oppo-release-r4-medicine.png`
- Evidence SHA-256:
  `6F199D2C25F7607849CCA00C7AE307894098380F1E07F14B9311EDB30723136C`

### `BUY-FV2-028` — Orders content-first phone layout

- Status: **IMPLEMENTED IN R17; AUTOMATED AND OPPO VERIFIED — FOUNDER
  ACCEPTANCE PENDING**
- Parent: `BUY-FV2-024`
- Destination: **Orders**
- Defect: The large Orders heading, Mool Assist action, three summary cards and
  Active/Delivered selector consume substantial phone height before the first
  order, reducing the visible order history and active-order detail.
- Required outcome: Orders must meet the founder's responsive 80–90% useful
  order-content visibility target by compacting its upper hierarchy and
  spacing across supported Android and iOS phones.
- Orders-specific boundary: Orders has no product category selector or
  three-product-grid requirement. Active/delivered states, counts, promised
  dates, fulfilment identities, progress, Track and help actions must remain
  clear and directly usable.
- Evidence:
  `artifacts/quality/buy-flutter-v2-oppo-20260729-01/39-oppo-release-r6-orders-currency.png`
- Evidence SHA-256:
  `1C05E565A3037C1E7C9BA6428F75F297D862C55A8FAB3F0244370B8A1DD1F250`

Child-ticket boundary: `BUY-FV2-025` through `BUY-FV2-028` split the same
founder defect into independently verifiable destinations. They do not
authorize implementation, HTML edits, reference replacement, commits or
promotion.

### `BUY-FV2-029` — Open the customer account from every app depth

- Status: **IMPLEMENTED IN R17; AUTOMATED AND OPPO VERIFIED — FOUNDER
  ACCEPTANCE PENDING**
- Registered: 29 July 2026
- Founder observation: Tapping the top-right **DC** customer control does not
  open anything about the customer account.
- Controlled OPPO reproduction: The visible node is exposed as
  `Profile / DC` at `[608,102][696,190]` but is marked `clickable="false"`.
  Tapping the centre of those visible bounds did not open an account surface;
  it surfaced the unrelated **Find by product code** sheet.
- Expected result: The signed-in customer's account must be directly accessible
  from anywhere in the app, including main destinations, subactions and
  tertiary actions.
- Severity: **P1 — global account-access and navigation-wiring defect**
- Candidate observed: `com.moolsocial.app` version `1.0.0`
  (`versionCode 2026072912`), isolated OPPO device-review candidate.

Acceptance criteria for the later authorized implementation:

1. The `DC` account affordance opens the native customer account/profile
   destination; it never behaves as a dead control and never invokes search,
   scan, product-code or another unrelated action.
2. A consistent direct account affordance is reachable across every main
   destination and from all subaction and tertiary-action depths without
   requiring the customer to unwind to a home screen first.
3. All entry points resolve to the same production account/session owner and
   do not duplicate profile, identity, address or authentication truth in UI
   state.
4. Closing or navigating back from the account returns to the exact originating
   destination and preserves Cart, checkout, order, search, category,
   prescription and scroll state where applicable.
5. The control is a real semantic button with an accurate account/profile
   label, `clickable=true`, a minimum 44 logical-pixel effective target and
   keyboard/screen-reader access.
6. The behavior is responsive and equivalent on supported Android and iOS
   phones, including safe areas, text scaling, deep links, retained sessions
   and authenticated relaunch.
7. A route-depth matrix proves direct account access and exact return behavior
   from main, subaction and tertiary states across Shop, Wholesale, Medicine,
   Orders and the other registered production destinations.

Locked-boundary note:

- The founder has registered the expected behavior as app-wide.
- This registration does not itself authorize edits to frozen Screens 01–03 or
  the Social/YouTube baseline. Any later implementation that would alter those
  accepted surfaces must first pass the repository's explicit founder
  authority and baseline-update workflow.

Evidence captured around the single controlled tap:

- Unobstructed before screenshot:
  `artifacts/quality/buy-flutter-founder-tickets-oppo-20260729-04/03b-oppo-account-target-before.png`
- Before screenshot SHA-256:
  `0F3019A5E954BDB8019A5C16B6550663E013A7BD44AE349A8EEF165DB5D9BA0C`
- Before UI hierarchy:
  `artifacts/quality/buy-flutter-founder-tickets-oppo-20260729-04/03b-oppo-account-target-before.xml`
- Before hierarchy SHA-256:
  `C363C73F125937EA22EF2B3147F3DD16B74B22A6781F3991A1C13D84EAC4C1EC`
- After-tap screenshot:
  `artifacts/quality/buy-flutter-founder-tickets-oppo-20260729-04/03c-oppo-account-tap-after.png`
- After-tap screenshot SHA-256:
  `8B9CD09E5A6D93D8623E1BEA093398BFB9AE50A42ABEF1C6CA753C7E0AC08E5A`
- After-tap UI hierarchy:
  `artifacts/quality/buy-flutter-founder-tickets-oppo-20260729-04/03c-oppo-account-tap-after.xml`
- After-tap hierarchy SHA-256:
  `93531389BD8F31F2B8BA468F6F3CCF2A9513D27D141F4D4FA39099C56CA4FF5A`

Registration boundary: this ticket records the founder defect, captured
misrouting and app-wide acceptance contract only. No Flutter implementation,
HTML, approved reference, route, test or golden was changed as part of this
ticket-registration pass.

### `BUY-FV2-030` — Launch a real camera and barcode scanner

- Status: **IMPLEMENTED IN R17; PRIMARY OPPO PATH VERIFIED — FOUNDER
  ACCEPTANCE AND FULL EDGE-STATE DEVICE MATRIX PENDING**
- Registered: 29 July 2026
- Founder observation: Tapping the scanner icon to the right of Search opens an
  incorrect, oversized bottom popup. The action should open camera, scanner and
  barcode-scanning capability, with a smaller modern high-technology
  presentation.
- Controlled OPPO reproduction: The semantic `Scan` button at
  `[604,330][692,418]` opens a bottom sheet beginning at approximately y=1072.
  The sheet contains only **Find by product code**, a manual
  **Barcode or product code** field and **Find product**. It exposes no camera
  preview, live scanner, barcode acquisition frame or scan state.
- Current affected destinations: **Shop and Wholesale**, through their shared
  scanner control. The same contract applies to any later Buy destination that
  exposes the `Scan` action.
- Severity: **P1 — primary product-discovery action does not provide its
  represented capability**
- Candidate observed: `com.moolsocial.app` version `1.0.0`
  (`versionCode 2026072912`), isolated OPPO device-review candidate.

Acceptance criteria for the later authorized implementation:

1. Tapping `Scan` launches a native camera-backed scanner experience rather
   than a manual-entry-only bottom sheet.
2. The live experience provides a clear barcode/scan frame, camera preview,
   active scanning state and an immediate cancel/return action.
3. Recognized product identifiers resolve through the existing production
   catalogue/search owner and return the customer directly to the matching
   product or an unambiguous result selection.
4. Manual barcode or product-code entry remains available as a compact fallback
   rather than the primary scanner experience.
5. Any popup or mode/fallback panel is materially smaller and more compact than
   the captured sheet. It uses a founder-approved modern scanner presentation
   and does not obscure most of the underlying catalogue.
6. The native flow covers camera permission request, denial, permanent denial
   with Settings return, unavailable camera, low light/torch, focus, invalid or
   unsupported code, no catalogue match, multiple matches, offline/service
   failure, retry and successful return.
7. Camera activity starts only after deliberate customer action and permission,
   stops when the scanner closes or the app backgrounds, and does not retain or
   upload imagery outside the approved product-resolution contract.
8. Scan feedback, reduced motion, sound/haptic preferences, semantic labels,
   focus order and minimum effective targets satisfy the accessibility and
   customer-copy gates.
9. The scanner and compact fallback are responsive across supported Android
   and iOS phones, safe areas, portrait/landscape, display scaling and supported
   accessibility text.
10. Automated and physical-device tests prove Shop and Wholesale entry,
    camera/permission states, product resolution and exact return to the
    originating query, category, scroll and Cart state.

Authority boundary for later implementation:

- “Smaller”, “modern” and “high-technology” require a new founder-reviewed
  scanner visual/state contract before Flutter implementation.
- Freeze the approved compact popup, camera overlay and failure states as a new
  immutable reference/interaction-contract version; do not overwrite the
  existing Buy v1 authority.
- The production implementation must use native Flutter/platform camera and
  barcode capabilities, never HTML or WebView presentation.

Evidence captured around the controlled scanner tap:

- Before screenshot:
  `artifacts/quality/buy-flutter-founder-tickets-oppo-20260729-04/04a-oppo-scanner-before.png`
- Before screenshot SHA-256:
  `C000A81D820BAC76083C8A96754E775BE77EA44C80A7963265B87DCB05F75050`
- Before UI hierarchy:
  `artifacts/quality/buy-flutter-founder-tickets-oppo-20260729-04/04a-oppo-scanner-before.xml`
- Before hierarchy SHA-256:
  `C363C73F125937EA22EF2B3147F3DD16B74B22A6781F3991A1C13D84EAC4C1EC`
- Popup screenshot:
  `artifacts/quality/buy-flutter-founder-tickets-oppo-20260729-04/04b-oppo-scanner-popup-current.png`
- Popup screenshot SHA-256:
  `AE43782E7A53BF64DCEBD003E5C8C3DF13E52639FF50199A512F65EBC158CDEC`
- Popup UI hierarchy:
  `artifacts/quality/buy-flutter-founder-tickets-oppo-20260729-04/04b-oppo-scanner-popup-current.xml`
- Popup hierarchy SHA-256:
  `93531389BD8F31F2B8BA468F6F3CCF2A9513D27D141F4D4FA39099C56CA4FF5A`

Registration boundary: this ticket records the founder defect, scanner
capability contract and captured evidence only. No Flutter implementation,
camera package, permission, HTML, approved reference, route, test or golden was
changed as part of this ticket-registration pass.

### `BUY-FV2-031` — Put Saved products at the product-grid interaction point

- Status: **IMPLEMENTED IN R17; AUTOMATED AND OPPO VERIFIED — FOUNDER
  ACCEPTANCE PENDING**
- Registered: 29 July 2026
- Founder observation: The Saved products control and popup are positioned near
  the customer-account area. Saved products should instead be available
  instantly where the customer is interacting with the product grid.
- Controlled OPPO reproduction: The `Saved` button is at
  `[504,102][592,190]`, immediately beside `Profile / DC` in the top identity
  header. Its popup begins at approximately y=870 and covers the lower
  catalogue with a large **Saved products** sheet.
- Affected destinations: **Shop, Wholesale and Medicine** product catalogues.
- Related density contract: `BUY-FV2-024` through `BUY-FV2-027`.
- Severity: **P1 — cross-catalogue saved-product discoverability and
  interaction-context defect**
- Candidate observed: `com.moolsocial.app` version `1.0.0`
  (`versionCode 2026072912`), isolated OPPO device-review candidate.

Acceptance criteria for the later authorized implementation:

1. Remove Saved products from the account/identity action cluster and place a
   compact Saved affordance at the product-grid interaction level.
2. The affordance remains immediately reachable while the customer browses,
   filters, selects categories, scrolls and changes quantities in Shop,
   Wholesale and Medicine.
3. Opening Saved products uses a compact contextual tray, panel or grid-level
   surface that does not obscure most of the product grid or defeat the
   80–90% content-visibility contract.
4. Saving or unsaving a product gives immediate local feedback at the
   originating product tile and keeps the Saved affordance/count synchronized.
5. Selecting a saved item opens the correct destination-specific offer and
   returns to the exact previous query, category, scroll, quantity and Cart
   state.
6. Shared canonical products retain their identity while Shop, Wholesale and
   Medicine offer, pack, seller, prescription and fulfilment differences remain
   explicit.
7. Empty, loading, unavailable, price-changed, out-of-stock, offline and retry
   states remain compact, customer-ready and actionable at the grid context.
8. The grid-level Saved interaction is responsive across supported Android and
   iOS phone sizes, three-tile layouts, safe areas, orientation, display scaling
   and accessibility text.
9. Semantic labels distinguish saving/unsaving one product from opening all
   Saved products, and every control has an effective minimum 44
   logical-pixel target.

Authority boundary for later implementation:

- The exact compact placement and interaction pattern must be designed and
  founder-approved together with the new content-first catalogue authority from
  `BUY-FV2-024`; do not improvise it directly in Flutter.
- Freeze a new immutable HTML/reference and interaction-contract version
  without overwriting the existing Buy v1 authority.
- Implement the accepted result in native Flutter using the existing saved
  product/session owner.

Evidence captured around the controlled Saved tap:

- Buy before-state screenshot:
  `artifacts/quality/buy-flutter-founder-tickets-oppo-20260729-04/05b-oppo-saved-products-buy-before.png`
- Before screenshot SHA-256:
  `588538C9A1A241BABA2F8C343B84F9E8AF23D151B770997542EAC4593AA06247`
- Before UI hierarchy:
  `artifacts/quality/buy-flutter-founder-tickets-oppo-20260729-04/05b-oppo-saved-products-buy-before.xml`
- Before hierarchy SHA-256:
  `D14C4285EF22D22C099484D8EC2D2D1A500E84D56D6A91F2028A3F3542EC8334`
- Saved-products popup screenshot:
  `artifacts/quality/buy-flutter-founder-tickets-oppo-20260729-04/05c-oppo-saved-products-popup-current.png`
- Popup screenshot SHA-256:
  `1FD20C7D2594F313D84EFE98F3F21F8299CDE8B47FC1B12AF21E885F10E09EE7`
- Popup UI hierarchy:
  `artifacts/quality/buy-flutter-founder-tickets-oppo-20260729-04/05c-oppo-saved-products-popup-current.xml`
- Popup hierarchy SHA-256:
  `F57C578500E12FA2E3A9D75051EB9BF9F40FD3784C0C96B0406862A40E5CEED8`

Registration boundary: this ticket records the founder defect, contextual
Saved-products direction and captured evidence only. No Flutter implementation,
HTML, approved reference, route, test or golden was changed as part of this
ticket-registration pass.

## Subsequent founder implementation authorization and r15 validation

After the registration-only pass above, the founder explicitly authorized
native Flutter implementation of all five reported defects in the production
repository, with production-grade cross-verification and testing on the
connected OPPO. That later direction authorized implementation of
`BUY-FV2-023` through `BUY-FV2-031`; it did not authorize a commit, push,
deployment, publication, replacement of an approved reference, or a claim of
founder acceptance.

Final candidate identity:

- repository branch:
  `remediation/prototype-conformance-2026-07-20`
- unchanged starting `HEAD`:
  `5225bb8d36792cc8f7fb9dfcfe418b3f93b7ca1a`
- isolated OPPO device-review build:
  `com.moolsocial.app` version `1.0.0` (`versionCode 2026072915`)
- candidate APK SHA-256:
  `7D51A72EBD80F222244F7608989787D56E8B75B7F2A38E75C89365E436BB2916`
- pulled installed base APK SHA-256:
  `7D51A72EBD80F222244F7608989787D56E8B75B7F2A38E75C89365E436BB2916`
- device:
  OPPO CPH2375, Android 13, serial `2b3e0f71`, 720×1612 physical
  pixels / 360 logical-pixel phone width

Per-ticket device result:

1. `BUY-FV2-023`: Mool now replaces the Buy dock contents in place with
   Social, Buy, Eat, Ride, Book, Pay and Work. No large modal obscures the
   catalogue.
2. `BUY-FV2-024`–`BUY-FV2-028`: Shop, Wholesale, Medicine and Orders use the
   compact content-first shell. Catalogue destinations expose three tiles at
   the tested 360 logical-pixel width; categories open temporarily and close
   after selection.
3. `BUY-FV2-029`: the semantic 44-logical-pixel `DC` control pushes the
   existing Identity & documents account route from Buy main/subaction/tertiary
   depths. Android back returned from account to the originating Orders state.
4. `BUY-FV2-030`: Scan opens a native live camera barcode/QR scanner with
   close, torch, camera-switch and automatic detection. Manual code entry is a
   compact fallback.
5. `BUY-FV2-031`: product tiles own Save/Remove actions; the synchronized Saved
   count and list are beside the grid controls. A live OPPO toggle increased
   Shop Saved from three to four and immediately listed Fresh red onions.

Verification result:

- final `flutter analyze --fatal-infos`: pass, no issues
- final Buy screen suite: 24/24 pass
- final Buy session suite: 12/12 pass
- final Buy router suite: 7/7 pass
- customer-copy, state-complete copy, responsive/device-fitment and interaction
  gates: pass
- approved UI locks, founder Buy reference, brand integrity and Social
  protected baseline: pass
- Social protected tree remains
  `54851b4769c6a0087f586ce6c9325bbee1d7c790e06488eccae3a62ca953332e`
- two independently logged final affected regressions: 72/72 pass in each run
- final package-process OPPO logcat: zero matches for `FATAL EXCEPTION`,
  `Unhandled Exception`, `RenderFlex overflow` or `E/flutter`

Durable candidate evidence:

- `artifacts/quality/buy-flutter-founder-tickets-oppo-20260729-05/README.md`
- `artifacts/quality/buy-flutter-founder-tickets-oppo-20260729-05/SHA256SUMS.txt`
- `artifacts/quality/buy-flutter-founder-tickets-oppo-20260729-05/regression-r15-1.log`
- `artifacts/quality/buy-flutter-founder-tickets-oppo-20260729-05/regression-r15-2.log`
- `artifacts/quality/buy-flutter-founder-tickets-oppo-20260729-05/oppo-r15-final-scoped-logcat.log`

This candidate is not a production release or proof of live commerce backend
activation. Founder visual acceptance, release signing, live integrations and
promotion remain separate gates. No commit, push, deployment or publication
was performed.

## Founder rejection of r15

The founder subsequently rejected the complete r15 result as not solving the
five reported defects and as not being production-grade. The earlier automated
passes, device checksum match and screenshots remain valid evidence of what was
tested, but they do not constitute visual or product acceptance. Tickets
`BUY-FV2-023` through `BUY-FV2-031` are therefore reopened.

The rejection specifically requires a fresh audit of every Buy journey, tap and
screen, including additional defects not explicitly pointed out by the
founder. The durable audit is:

- `docs/quality/BUY-V2-R15-FOUNDER-REJECTION-UIUX-AUDIT-20260729.md`

### `BUY-FV2-032` — Declutter the shared Buy app bar

- Status: **IMPLEMENTED IN R17; AUTOMATED AND OPPO VERIFIED — FOUNDER
  ACCEPTANCE PENDING**
- Severity: **P1**
- Affected scope: every Buy main, subaction and tertiary screen.
- Defect: the MoolSocial wordmark, delivery/business/pharmacy context, Search,
  Scanner and DC account actions are compressed into one 360-logical-pixel row.
  Context is truncated, the circular controls visually dominate and the header
  has no clear priority.
- Required outcome:
  1. Keep one stable, maximum-48-logical-pixel brand/context/account app bar.
  2. Move catalogue discovery controls into a separate compact product toolbar
     instead of forcing five competing elements into the brand row.
  3. Keep the full wordmark, meaningful one-line context and a directly
     reachable 44-pixel account target without collisions at 320–430 logical
     pixels and supported text scales.
  4. Use the same hierarchy across Shop, Wholesale, Medicine, Orders, product,
     Cart, Checkout, confirmation, tracking and Assist.

### `BUY-FV2-033` — Guarantee the core-content viewport and remove overlays

- Status: **IMPLEMENTED IN R17; AUTOMATED AND OPPO VERIFIED — FOUNDER
  ACCEPTANCE PENDING**
- Severity: **P1**
- Defect: the current first product begins around physical y=292 while the dock
  begins around y=1368 on the 1612-pixel OPPO. Only about two-thirds of the
  complete device screen is unobscured grid space, despite the founder's
  80–90% content-first direction. The dock is positioned over content and the
  grid compensates with 118 logical pixels of bottom padding.
- Required outcome:
  1. Shared top chrome must consume no more than 16% of the safe body on common
     phones.
  2. The stable bottom navigation must consume no more than 8% of the safe body.
  3. The remaining core-content region must be at least 80% of the safe body and
     must not be painted or tapped through a floating overlay.
  4. These rules apply to catalogue, Orders and every deeper Buy view.

### `BUY-FV2-034` — Replace tall, truncated product tiles with readable dense cards

- Status: **IMPLEMENTED IN R17; AUTOMATED AND OPPO VERIFIED — FOUNDER
  ACCEPTANCE PENDING**
- Severity: **P1**
- Defect: r15 three-column cards are fixed at 246 logical pixels, expose only
  about two rows before the dock, contain large blank interiors and attempt to
  fit by using 6–9-pixel product metadata. Badges, seller names, delivery facts
  and placeholder labels truncate or overlap Save controls.
- Required outcome:
  1. Show three complete readable cards per row at the normal 360-pixel phone
     width and at least three useful rows in the initial catalogue viewport.
  2. Remove fixed internal spacers and blank vertical gaps.
  3. Keep product name, pack, price, seller/fulfiller and delivery promise
     legible without 6-pixel customer copy.
  4. Keep Save and purchase controls visually separate from badges and product
     artwork while retaining 44-pixel effective targets.
  5. Remove clipped placeholder labels such as `NOTEBO` and inconsistent
     bookmark states.

### `BUY-FV2-035` — Make catalogue tools contextual instead of interrupting

- Status: **IMPLEMENTED IN R17; AUTOMATED AND OPPO VERIFIED — FOUNDER
  ACCEPTANCE PENDING**
- Severity: **P1**
- Reopens: `BUY-FV2-024`–`BUY-FV2-028` and `BUY-FV2-031`.
- Defect: the category control still occupies most of a full toolbar; opening
  categories pushes the grid down another 82 logical pixels. Search, Saved and
  Filter still open modal sheets, and Saved continues to cover the grid.
- Required outcome:
  1. Use a compact category button and an anchored, non-layout-shifting picker.
  2. Provide a compact in-toolbar search affordance with Scanner immediately
     beside it.
  3. Make Saved an in-grid browse mode/filter with synchronized tile actions,
     not a covering Saved-products sheet.
  4. Keep filters, active orders, household basket and prescriptions reachable
     through compact contextual controls that do not crowd the account area or
     permanently reduce the grid.
  5. Preserve the exact selected category/query/filter/scroll state after each
     interaction.

### `BUY-FV2-036` — Stabilize Mool and Buy bottom navigation

- Status: **IMPLEMENTED IN R17; AUTOMATED AND OPPO VERIFIED — FOUNDER
  ACCEPTANCE PENDING**
- Severity: **P1**
- Reopens: `BUY-FV2-023`.
- Defect: the 72-pixel floating animated dock overlays content, changes between
  six and seven actions and has produced transient frames with missing icons or
  labels after taps. Long labels are compressed into narrow animated cells.
- Required outcome:
  1. Use one reserved, safe-area-aware navigation region with a stable height
     and stable item geometry.
  2. Mool may reveal the seven primary actions inside that region, but the rail
     must not animate content into unreadable or temporarily blank states.
  3. Every item must retain a 44-pixel effective target, clear selected state
     and deterministic return to the Buy subnavigation.
  4. Navigation may never hide product, quantity, checkout, tracking or support
     actions.

### `BUY-FV2-037` — Make product facts and purchase action visible together

- Status: **IMPLEMENTED IN R17; AUTOMATED AND OPPO VERIFIED — FOUNDER
  ACCEPTANCE PENDING**
- Severity: **P1**
- Defect: product detail uses an oversized hero, 25-pixel title and stacked fact
  panels. The customer must scroll through most of the page before reaching Add
  to cart or Use Rx, and the bottom dock can cover the action.
- Required outcome:
  1. Present product identity, pack, price, fulfilment and primary purchase
     action within the initial phone viewport.
  2. Keep a non-obscuring sticky purchase/quantity action above the reserved
     navigation region.
  3. Use progressive disclosure for secondary medicine, provenance and policy
     facts without removing regulated information.
  4. Preserve prescription, quantity, Cart and return-state behavior.

### `BUY-FV2-038` — Compact Cart, Checkout, address, payment and confirmation

- Status: **IMPLEMENTED IN R17; AUTOMATED AND OPPO VERIFIED — FOUNDER
  ACCEPTANCE PENDING**
- Severity: **P1**
- Defect: large headings, summary blocks, family cards and CTA bands consume
  excessive height. Cart and confirmation show large unused white regions;
  Checkout actions compete with the floating dock; address and payment sheets
  use oversized typography and rows.
- Required outcome:
  1. Use compact sticky totals/actions that sit above, not behind, navigation.
  2. Remove blank reserved regions and show more Cart lines and fulfilment
     groups in the first viewport.
  3. Keep address and payment choices readable in compact, scroll-safe sheets
     across keyboard, safe-area and text-scale states.
  4. Show confirmation identifiers, total, destination and next actions without
     a full-screen success billboard.

### `BUY-FV2-039` — Compact Orders, tracking and Mool Assist

- Status: **IMPLEMENTED IN R17; AUTOMATED AND OPPO VERIFIED — FOUNDER
  ACCEPTANCE PENDING**
- Severity: **P1**
- Defect: order summary/tabs delay the first order, order cards repeat oversized
  controls, tracking uses 26-pixel titles and tall panels, and Assist uses large
  headings/chips with substantial empty space.
- Required outcome:
  1. Begin the first order within 150 logical pixels of the Buy safe-body top.
  2. Show at least two complete active-order cards plus the start of a third on
     a 360×800 logical viewport.
  3. Keep Track, help, reorder, account and return actions immediately
     reachable and never covered by navigation.
  4. Compress tracking and Assist without removing partner, promise, progress,
     safety or communication facts.

### `BUY-FV2-040` — Finish the scanner as a compact production tool

- Status: **IMPLEMENTED IN R17; PRIMARY OPPO PATH VERIFIED — FOUNDER
  ACCEPTANCE AND FULL EDGE-STATE DEVICE MATRIX PENDING**
- Severity: **P1**
- Reopens: `BUY-FV2-030`.
- Defect: r15 launches the camera, but its bottom instruction panel and manual
  code sheet still consume substantial screen area. Recovery and result
  presentation remain visually disconnected from the compact catalogue tools.
- Required outcome:
  1. Keep the live frame, close, torch and camera-switch controls stable across
     supported safe areas.
  2. Reduce scanner chrome to one compact instruction/action band.
  3. Use a compact manual-code surface that remains usable with the keyboard
     and returns to the exact catalogue state.
  4. Verify permission, denial, settings, unavailable camera, unsupported code,
     no match, retry and success states without placeholder copy or overflow.

### `BUY-FV2-041` — Enforce a visual and responsive production matrix

- Status: **R17 AUTOMATED MATRIX AND OPPO REPLAY COMPLETE — FOUNDER
  ACCEPTANCE PENDING**
- Severity: **P1 release gate**
- Defect: passing functional/widget tests did not detect the founder-visible
  crowding, unreadable metadata, excessive whitespace, overlay or transient
  navigation defects.
- Required outcome:
  1. Capture and micro-audit every main/subaction/tertiary Buy state at 320×568,
     360×800, 390×844 and 430×932 logical viewports.
  2. Repeat critical states at 140% text and with Android/iOS safe-area
     profiles.
  3. Add measurable top-chrome, content-start, dock, card-density, no-overlap
     and no-truncation assertions.
  4. Replay every journey and interaction on the exact checksum-matched OPPO
     APK before any acceptance claim.
  5. Automated passes are necessary evidence but never override a
     founder-visible failure.

## Founder-remediation candidate r17

The founder subsequently authorized implementation, a fresh visual audit and
OPPO replay of the reopened tickets. The resulting native Flutter remediation
candidate is r17. This section records implementation and verification only;
it does not close the founder-acceptance gate.

Candidate identity:

- branch: `remediation/prototype-conformance-2026-07-20`
- unchanged starting `HEAD`:
  `5225bb8d36792cc8f7fb9dfcfe418b3f93b7ca1a`
- package: `com.moolsocial.app`
- version: `1.0.0` (`versionCode 2026072917`)
- tested candidate:
  `moolsocial-buy-founder-remediation-r17-oppo-review-debug.apk`
- candidate and pulled installed-base SHA-256:
  `600203DF3D3A2E77B9E44E92E5042F7CBD060251F419378E5DC5800DE1659342`
- physical device: OPPO CPH2375, Android 13, serial `2b3e0f71`,
  720×1612 physical pixels / 360 logical-pixel phone width

The prior r16 archive is retained. Its normal production-auth launch correctly
reached sign-in, but the configured local authentication service was not
reachable from the physical OPPO. R17 was therefore built from the same tested
source state with the repository's device-review mode so the exact Buy
candidate could be replayed without weakening or modifying the production auth
flow.

R17 ticket evidence:

1. `BUY-FV2-023` / `BUY-FV2-036`: `11-r17-mool-rail-oppo.png` shows
   the seven Mool actions replacing the Buy destinations inside the same
   reserved 54-logical-pixel rail, without a modal or content overlay.
2. `BUY-FV2-024`–`BUY-FV2-028` / `BUY-FV2-032`–`BUY-FV2-035`:
   `10-r17-shop-oppo.png`, `21-r17-wholesale-oppo.png`,
   `22-r17-medicine-oppo.png` and `23-r17-orders-oppo.png` show the compact
   two-level top hierarchy and content-first views. Shop, Wholesale and
   Medicine expose three readable product columns. Orders exposes three
   complete active-order cards.
3. `BUY-FV2-029`: `20-r17-account-from-shop-oppo.png`,
   `26-r17-account-from-tracking-oppo.png` and
   `29-r17-account-from-product-oppo.png` prove the 44-logical-pixel account
   action from primary, tertiary and product-detail depths.
4. `BUY-FV2-030` / `BUY-FV2-040`:
   `17-r17-scanner-camera-or-permission-oppo.png` shows the native live camera,
   scan frame, close, torch, camera-switch and compact instruction band.
   `18-r17-scanner-manual-sheet-oppo.png` shows the compact keyboard-safe
   fallback. The complete physical-device denial/settings/unavailable/no-match
   matrix remains an explicit acceptance prerequisite.
5. `BUY-FV2-031`: `19-r17-saved-inline-grid-oppo.png` shows Saved as an inline
   grid browse mode rather than a covering sheet.
6. `BUY-FV2-037`–`BUY-FV2-039`: product, Cart, Checkout, address, payment,
   confirmation, tracking and Assist are recorded in
   `28-r17-product-detail-oppo.png` through
   `38-r17-order-confirmation-oppo.png`, plus
   `25-r17-tracking-settled-oppo.png` and
   `27-r17-order-help-oppo.png`.
7. The regulated Medicine path is recorded in
   `39-r17-medicine-prescription-sheet-oppo.png` through
   `44-r17-medicine-checkout-settled-oppo.png`. A non-matching family
   prescription does not add the medicine; the matching prescription does.
8. Mixed Medicine/Wholesale quantity, Cart and Checkout state is recorded in
   `45-r17-wholesale-return-oppo.png` through
   `51-r17-multi-scope-checkout-third-capture-oppo.png`.

Verification:

- `flutter analyze --fatal-infos`: pass
- focused Buy tests: screen 27/27, session 12/12 and router 8/8 pass
- copy, responsive/device-fitment and affected Screen 04 tests: 32/32 pass
- two complete affected regressions: 76/76 pass in each independent run
- 58 local responsive screenshots cover 320×568, 360×800, 390×844 and
  430×932 Android/iOS-size profiles, including 140% text critical states
- founder-final Buy reference: 25 immutable files pass
- user-facing copy and 154-route interaction gates: pass
- approved UI locks and brand-integrity gates: pass
- Social protected baseline: 119 files pass with exact tree
  `54851b4769c6a0087f586ce6c9325bbee1d7c790e06488eccae3a62ca953332e`
- the r17 app-scoped OPPO log contains no `FATAL EXCEPTION`, `E/flutter`,
  `FlutterError`, `RenderFlex`, overflow or unhandled-exception match

Durable append-only evidence is under:

`artifacts/quality/buy-flutter-founder-remediation-oppo-20260729-06`

No approved HTML, locked Screen 01–03 source or protected Social/YouTube source
was changed. No commit, push, deployment or publication was performed.

## Founder rejection of r17

On 30 July 2026 the founder rejected the r17 Buy candidate as visually
unsatisfactory and unacceptable. R17 remains preserved as tested evidence; its
passing tests and checksum match do not constitute product acceptance.

The founder identified that:

- the delivery/business identity block is visually broader and more dominant
  than Search, with the MoolSocial wordmark insufficiently distinguished from
  location or workspace context;
- Cart is reduced to a quiet toolbar icon even though it is the buyer's primary
  conversion focus;
- the opened category surface is excessively wide and tall and does not have a
  professional product-navigation treatment;
- Orders repeats oversized cards and action bands and wastes space;
- tracking, account and other deeper Buy screens use inconsistent shapes,
  widths, typography and navigation and leave large vacant regions;
- the same problems must be solved systematically across Shop, Wholesale,
  Medicine, Orders and every nested Buy state, including supported Android and
  iOS-size viewports.

Exact rejected-state OPPO evidence:

`artifacts/quality/buy-flutter-r17-founder-rejection-oppo-20260730-07`

### `BUY-FV2-042` — Establish one professional compact Buy design system

- Status: **IN PROGRESS — REGISTERED FROM FOUNDER R17 REJECTION**
- Severity: **P1**
- Affected scope: every Buy primary, secondary and tertiary state.
- Required outcome:
  1. Standardize page gutters, card radii, border weight, elevation, icon
     sizes, typography, spacing, control heights and selected states.
  2. Keep every effective tap target at least 44 logical pixels while allowing
     the visible control treatment to remain compact.
  3. Remove oversized text, controls, repeated empty panels and unexplained
     vacant regions without creating clutter.
  4. Apply the system consistently at 320–430 logical-pixel phone widths,
     Android/iOS safe areas and 140% text.

### `BUY-FV2-043` — Separate brand, context, Search and account hierarchy

- Status: **IN PROGRESS — REGISTERED FROM FOUNDER R17 REJECTION**
- Severity: **P1**
- Reopens: `BUY-FV2-032`.
- Rejected-state measurement: on the OPPO, the location/workspace context owns
  physical bounds `[186,84][608,172]` while the Search semantic content is only
  `[114,207][302,243]`. The wordmark and context appear attached inside the
  same undifferentiated band.
- Required outcome:
  1. Give the MoolSocial identity a distinct stable brand zone.
  2. Keep delivery, business or pharmacy context subordinate and concise.
  3. Make Search the dominant catalogue discovery control beneath the identity
     row, with Scanner immediately available.
  4. Keep the account owner continuously reachable without letting the account
     avatar dominate the header.

### `BUY-FV2-044` — Restore Cart as a prominent buyer focus

- Status: **IN PROGRESS — REGISTERED FROM FOUNDER R17 REJECTION**
- Severity: **P1**
- Reopens: `BUY-FV2-038`.
- Defect: r17 represents a non-empty Cart as one 44-pixel icon among Saved and
  overflow actions.
- Required outcome:
  1. Implement the approved compact Cart indicator with quantity and payable
     total immediately above the persistent Buy dock.
  2. Reserve its space rather than hiding products or purchase actions behind
     it.
  3. Preserve the exact source catalogue, product and quantity state on
     open/return.
  4. Keep Cart reachable from every catalogue and purchase depth.

### `BUY-FV2-045` — Replace the oversized category popup

- Status: **IN PROGRESS — REGISTERED FROM FOUNDER R17 REJECTION**
- Severity: **P1**
- Reopens: `BUY-FV2-035`.
- Rejected-state measurement: the first category row spans physical bounds
  `[16,114][464,202]`; the surface continues almost to the bottom dock and
  obscures most of the catalogue.
- Required outcome:
  1. Use a restrained adaptive category surface with bounded width and height,
     clear selected state and professional shape/elevation.
  2. Preserve category scrolling without turning the selector into a
     near-full-screen rail.
  3. Close immediately after selection and restore the complete three-column
     grid without a layout jump.
  4. Apply the same control treatment to Shop, Wholesale and Medicine.

### `BUY-FV2-046` — Standardize readable dense catalogue cards

- Status: **IN PROGRESS — REGISTERED FROM FOUNDER R17 REJECTION**
- Severity: **P1**
- Reopens: `BUY-FV2-024`–`BUY-FV2-027` and `BUY-FV2-034`.
- Defect: r17 cards use oversized prices and Add bands but still truncate the
  delivery commitment, named partner and partner type.
- Required outcome:
  1. Establish one compact information rhythm for product identity, pack,
     price, delivery, partner and purchase action.
  2. Keep three useful columns at the normal OPPO width while exposing at least
     three rows and the next-row continuation.
  3. Never obtain density through unreadably small or clipped decision text.
  4. Preserve Save, Rx and MOQ/quantity behavior across all three catalogues.

### `BUY-FV2-047` — Turn Orders, tracking and Assist into compact working tools

- Status: **IN PROGRESS — REGISTERED FROM FOUNDER R17 REJECTION**
- Severity: **P1**
- Reopens: `BUY-FV2-039`.
- Rejected-state measurement: each r17 active-order card repeats physical
  88-pixel Track and Get help bands; tracking content ends at approximately
  physical y=1132 and leaves the remainder of the body vacant.
- Required outcome:
  1. Remove repeated per-card support actions; retain one centralized Mool
     Assist as required by the approved contract.
  2. Use one clear tracking/reorder action per order with compact decision
     facts and progress.
  3. Use tracking space for fulfilment, destination, products, next steps and
     useful delivery controls rather than blank canvas.
  4. Keep all actions wired and return the customer to the exact Orders state.

### `BUY-FV2-048` — Provide a coherent Buy account hub and predictable back

- Status: **IN PROGRESS — REGISTERED FROM FOUNDER R17 REJECTION**
- Severity: **P1**
- Reopens: `BUY-FV2-029`.
- Defect: r17 opens a visually unrelated oversized Identity & documents screen
  directly from Buy and relies on route history rather than a consistent Buy
  return model.
- Required outcome:
  1. Open a compact Buy account hub from every Buy depth.
  2. Expose identity, delivery destinations, payments, Wholesale workspace,
     prescriptions, Orders and security through real wired actions.
  3. Preserve the originating Buy screen and state on return.
  4. Make Android/system back and visible back controls deterministic through
     product, Cart, Checkout, Orders, tracking, Assist and account.

### `BUY-FV2-049` — Standardize persistent primary and Buy navigation

- Status: **IN PROGRESS — REGISTERED FROM FOUNDER R17 REJECTION**
- Severity: **P1**
- Reopens: `BUY-FV2-023` and `BUY-FV2-036`.
- Required outcome:
  1. Use stable geometry for Mool primary actions and Buy destinations.
  2. Replace oversized selected blocks with a clear compact state treatment.
  3. Preserve all six Buy dock actions and all seven Mool actions without
     clipping or transient missing labels.
  4. Never cover Cart, Checkout, tracking or account actions.

### `BUY-FV2-050` — Prove r18 as a complete visual and navigation candidate

- Status: **IN PROGRESS — REGISTERED FROM FOUNDER R17 REJECTION**
- Severity: **P1 release gate**
- Required outcome:
  1. Micro-audit every catalogue, category, product, Cart, Checkout, address,
     payment, confirmation, Orders, tracking, Assist, account, Medicine and
     prescription state.
  2. Capture the responsive Android/iOS-size and 140% text matrix.
  3. Run focused checks after each logical implementation change and two
     complete regressions after the candidate stabilizes.
  4. Install the exact r18 artifact on the OPPO, pull the installed base APK,
     prove checksum equality and replay every tap and return path.
  5. Do not claim acceptance until the founder reviews the resulting candidate.

### `BUY-FV2-051` — Separate saved-address guidance from payment

- Status: **IN PROGRESS — REGISTERED FROM FOUNDER R17 REJECTION**
- Severity: **P1 customer-comprehension defect**
- Reopens: `BUY-FV2-038`.
- Founder direction: never present delivery and payment as one combined
  decision because the buyer may understand them as dependent or confuse which
  value is being changed.
- Required outcome:
  1. Present one subtle, concise reminder that the order will be delivered to
     the currently saved destination.
  2. Place a clear `Edit` action immediately beside that destination.
  3. Present payment separately with its own selected method and `Change`
     action.
  4. Remove combined labels and sentences such as `Delivery & payment` or
     wording that asks the customer to confirm address and payment together.
  5. Preserve the selected address independently when the payment method
     changes, and preserve the payment method independently when the address
     changes.

### `BUY-FV2-052` — Make every action responsive and every order visibly live

- Status: **IN PROGRESS — REGISTERED FROM FOUNDER R17 REJECTION**
- Severity: **P1 interaction-quality defect**
- Affected scope: every Buy tap, state change, submission, scanner action,
  quantity change, navigation transition and order-tracking state.
- Required outcome:
  1. Acknowledge every customer action immediately through a pressed or
     selected state, haptic feedback, inline state change, concise notice, or a
     progress indicator when real asynchronous work is occurring.
  2. Never insert artificial waiting merely to display a spinner.
  3. Prevent repeated submission while a genuine asynchronous action is in
     progress and show its completion or recovery result in context.
  4. Every active tracking view must show progress percentage, completed
     steps, the current live step, what happens next and the delivery promise.
  5. Use restrained live-status motion only when animations are enabled; keep
     the same information and selected-state clarity under reduced motion.
  6. Preserve screen-reader announcements, minimum tap targets and stable
     layout while progress feedback appears.

## R19 implementation and exact-device verification

Tickets `BUY-FV2-042` through `BUY-FV2-052` are now:

**IMPLEMENTED AND OPPO VERIFIED — FOUNDER ACCEPTANCE PENDING**

R18 was installed and broadly replayed first. That replay proved the new
header hierarchy, grid density, Cart, category surface, account hub, scanner,
Orders/tracking, Checkout, separate address/payment, Wholesale, Medicine and
prescription paths. It also exposed one remaining defect: Save feedback at the
correct catalogue interaction point was still a full-width banner.

The banner was corrected without overwriting r18 evidence. The final r19
candidate uses a compact right-anchored confirmation chip, a check icon, a
248-logical-pixel maximum width and a screen-reader live region.

Final candidate:

- version: `1.0.0` (`versionCode 2026073019`)
- APK:
  `moolsocial-buy-founder-remediation-r19-oppo-review-debug.apk`
- candidate and pulled installed-base SHA-256:
  `99D2032A4D173E13471ABACFD54BE36262F11552D99B8B882CB407723DB183BE`
- device: OPPO CPH2375, Android 13, serial `2b3e0f71`
- two complete affected regressions: 83/83 pass in each independent run
- final responsive matrix: 64 screenshots
- founder Buy reference, copy, 154-route interaction, Screens 01–03, brand and
  exact protected-Social-tree gates: pass
- app-scoped OPPO log: no Flutter error, RenderFlex overflow, fatal exception
  or unhandled exception match

Durable final evidence:

`artifacts/quality/buy-flutter-r19-founder-remediation-oppo-20260730-09`

Durable r17 rejection/r19 audit:

`docs/quality/BUY-V2-R17-FOUNDER-REJECTION-UIUX-AUDIT-20260730.md`

These statuses record implementation and verification. They do not close the
founder acceptance gate. No commit, push, deployment or publication was
performed.

## Post-R19 non-visual production hardening

### `BUY-FV2-053` — Fail closed for stale or unknown Buy identifiers

- Status: **COMPLETED — AUTOMATED AND CHECKSUM-MATCHED OPPO VERIFIED**
- Severity: **P1 data-integrity defect**
- Proven defect: `BuyV2Session.product` and `selectedOrder` used first-record
  fallbacks. An unknown product or order identifier from a stale deep link,
  scanner result, saved state or future adapter could therefore open or add a
  different real product/order.
- Scope: identifier lookup and regression coverage only. No layout, visual,
  branding, colour, motion, HTML or Social change is authorized.
- Acceptance:
  1. Unknown product routes remain in the current safe catalogue and show an
     honest not-found result.
  2. Unknown product IDs cannot add, save or mutate the first catalogue item.
  3. Unknown order routes open Orders with a not-found result and never expose
     another order's tracking data.
  4. Unknown saved-address IDs preserve the last valid address.
  5. Known product, order and address paths retain their existing behaviour.
  6. Focused tests, two same-source affected regressions and all protected
     gates pass before completion.

Completion evidence:

- Unknown product, order and saved-address identifiers now fail closed without
  substituting a catalogue product, order or address.
- Focused analysis passed and the affected Buy regression set passed twice
  against the same source state: 85/85 in each run.
- Founder Buy reference, customer-copy, 154-route interaction, approved UI
  locks, brand, protected Social tree and diff checks passed.
- The normal application build (`versionCode 2026073020`) correctly stopped at
  the existing protected sign-in boundary after installation. It was retained
  as diagnostic evidence and no protected authentication screen was changed.
- The established native Buy review entry was then built as
  `versionCode 2026073021`, installed on the connected OPPO and pulled back.
  Candidate and installed-base SHA-256 are identical:
  `611A3F23EF5AD0E35E5FC20FC0BFC133FFB126A718B789168C6B441FDB0E6CE7`.
- OPPO replay proved known Shop product, Orders and live tracking paths. The
  stale-route owner is covered at the router boundary because the local command
  policy correctly prevented synthetic malformed deep-link injection through
  ADB; it was not bypassed.
- Durable evidence:
  `artifacts/quality/buy-post-r19-hardening-20260730-10`.

### `BUY-FV2-054` — Protect independent Buy vertical contracts

- Status: **COMPLETED — TEST, AUDIT AND CHECKSUM-MATCHED OPPO VERIFIED**
- Severity: **P1 regression-prevention and future-adapter boundary**
- Proven gap: the production catalogue and session already separate Shop,
  Wholesale and Medicine, but no dedicated suite proves destination ownership
  for exact-ID search, category/filter state, product metadata and read-only
  cart views. A future data adapter could therefore leak offers or state across
  verticals without a focused contract failure.
- Scope: regression tests and a read-only backend gap audit only. No production
  application code, UI, HTML, Social code or speculative backend contract may
  be added.
- Acceptance:
  1. Catalogue IDs, destination counts, category ownership and mandatory
     product facts are protected.
  2. Shared Shop/Wholesale canonical products retain distinct offer IDs and
     vertical-specific price, fulfilment and minimum-order facts.
  3. Medicine records remain independently licensed and retain their
     prescription/regulatory facts.
  4. Exact-ID search, filters and category state cannot leak between Shop,
     Wholesale and Medicine.
  5. Public cart and destination collection views remain read-only.
  6. The current backend is inspected without mutation and every missing
     founder/API decision is explicitly deferred.
  7. Focused tests, two same-source affected regressions, an unchanged
     checksum-matched OPPO vertical replay and all protected gates pass.

Completion evidence:

- Six focused contracts protect 84 Shop offers, 84 Wholesale offers, eight
  Medicine records, category ownership, mandatory product facts, canonical
  identity versus offer identity, licensed Medicine facts, destination search
  isolation, independent category state and read-only exposed collections.
- Full Flutter analysis passed. The affected suite passed 91/91 twice against
  the same source state.
- The backend audit confirmed that the 79 backend files are YouTube-specific
  and that no Buy API, schema, data model or authorization contract currently
  exists. No speculative backend code was added.
- OPPO replay proved distinct Shop and Wholesale results for `tomato` and the
  independently licensed Medicine result for `ors`.
- The unchanged installed R21 base APK was pulled again. Its SHA-256 remains
  identical to the tested R21 candidate:
  `611A3F23EF5AD0E35E5FC20FC0BFC133FFB126A718B789168C6B441FDB0E6CE7`.
- All founder-reference, copy, interaction, approved-lock, brand, Social and
  diff gates passed. The app-scoped fatal/overflow filter is clean.
- Durable audit:
  `docs/quality/BUY-V2-BACKEND-GAP-AND-VERTICAL-CONTRACT-AUDIT-20260730.md`.
- Durable evidence:
  `artifacts/quality/buy-post-r19-vertical-contracts-20260730-11`.

### `BUY-FV2-055` — Align order-card touch and accessibility actions

- Status: **COMPLETED — CHECKSUM-MATCHED OPPO VERIFIED**
- Severity: **P1 functional interaction and accessibility defect**
- Proven defect: the OPPO accessibility tree exposed each complete active
  order card as one clickable node, but a physical tap on the card body did
  nothing. Only the nested `Track order` control completed the advertised
  action. Touch and accessibility behaviour were therefore inconsistent.
- Scope: order-card tap wiring, semantics congruence and tests only. No copy,
  layout, shape, size, colour, branding, animation, HTML or Social change is
  authorized.
- Acceptance:
  1. Tapping any non-control area of an active order card opens that exact
     order's tracking state.
  2. Tapping any non-control area of a delivered order card performs the same
     reversible `Reorder` preparation as its visible primary action.
  3. The nested visible primary control retains its existing behaviour and
     does not expose a duplicate accessibility action.
  4. A physical OPPO card-body tap proves the transition.
  5. Focused tests, two same-source affected regressions, exact candidate
     checksum proof and all protected gates pass.

Completion evidence:

- The complete order card now invokes the same existing primary action as its
  visible nested control. The nested control is excluded from duplicate
  semantics while retaining its physical tap behaviour.
- No order-card copy, dimension, decoration, colour, icon, progress treatment
  or motion changed.
- Focused screen tests passed 33/33. Full Flutter analysis passed. The affected
  suite passed 92/92 twice against the same source state.
- Every founder-reference, copy, interaction, approved-lock, brand, Social and
  diff gate passed.
- Native Buy R22 (`versionCode 2026073022`) was installed on the OPPO. The
  exact card-body coordinate that did nothing on R21 opened the correct
  `MS-240782` live tracking state on R22.
- Candidate and pulled installed-base SHA-256:
  `A2F3B312B6C655540976A3B946F6E8E279CEA89F06AC440BF2F683797B5AF5C1`.
- The app-scoped fatal/overflow filter is clean.
- Durable evidence:
  `artifacts/quality/buy-post-r19-order-card-action-20260730-12`.

### `BUY-FV2-056` — Fail closed for unknown saved prescriptions

- Status: **COMPLETED — CHECKSUM-MATCHED OPPO VERIFIED**
- Severity: **P0 Medicine authorization and data-integrity defect**
- Proven defect: `approveSavedPrescription` mapped `meera` explicitly but
  treated every other identifier as `arvind`. An unknown or stale saved
  prescription ID could therefore authorize real prescription-only medicines.
- Scope: saved-prescription identifier validation, failure-state copy and
  regression coverage only. No medicine rule, matching rule, quantity, UI
  layout, visual treatment, HTML, backend or Social change is authorized.
- Acceptance:
  1. Only the established `meera` and `arvind` IDs authorize their existing
     medicine sets.
  2. An unknown ID authorizes no medicine, attaches no prescription, adds no
     cart line and does not discard a pending medicine selection.
  3. The customer receives an honest not-found result and can immediately
     choose a valid saved prescription.
  4. Existing valid prescription selection and quantity limits remain
     unchanged.
  5. Focused tests, two same-source affected regressions, known-path OPPO
     replay, exact candidate checksum proof and all protected gates pass.

Completion evidence:

- `meera` and `arvind` now resolve explicitly. Any other ID fails closed,
  attaches nothing, authorizes nothing, adds nothing and preserves the pending
  medicine for immediate retry.
- Focused session tests passed 16/16. Full Flutter analysis passed. The
  affected suite passed 93/93 twice against the same source state.
- Every founder-reference, copy, interaction, approved-lock, brand, Social and
  diff gate passed.
- R23 OPPO replay proved that choosing Metformin, opening the saved
  prescription owner and selecting Dr Arvind Joshi still adds exactly one
  authorized Metformin line with the existing quantity limit.
- Candidate and pulled installed-base SHA-256:
  `3E1584C6BE7B0D5B1C7A94C521BD35BB73B0E73BE317003BEE4842258F7453A8`.
- The app-scoped fatal/overflow filter is clean.
- Durable evidence:
  `artifacts/quality/buy-post-r19-prescription-id-20260730-13`.

### `BUY-FV2-057` — Keep reorder restoration atomic and vertical-safe

- Status: **COMPLETED 2026-07-30**
- Severity: **P1 cart and vertical data-integrity defect**
- Proven defect: `reorder` trusted every `productId` in an order. A Shop order
  containing a Wholesale product ID could add the Wholesale line and then open
  a Shop-scoped cart. Unknown IDs were silently skipped before reporting that
  previous products were ready.
- Scope: reorder reference preflight and regression coverage only. Existing
  historical fallback products, valid exact reorders, prescription rules,
  cart UI, copy outside the failure result, HTML, backend and Social are
  unchanged.
- Acceptance:
  1. Every explicit order product ID must resolve and belong to the order's
     destination before any cart mutation occurs.
  2. An unknown, cross-vertical or empty invalid restoration mutates no cart
     line and reports an honest not-found result.
  3. Existing unrelated cart lines remain untouched after a rejected reorder.
  4. Existing historical fallback and newly confirmed exact reorder paths
     retain their behaviour.
  5. Focused tests, two same-source affected regressions, known-path OPPO
     replay, exact candidate checksum proof and all protected gates pass.

- Production result:
  - `BuyV2Session.reorder` now preflights the complete restoration set before
    mutating the cart. An empty set, unresolved product or destination mismatch
    returns `false`, preserves every cart line and exposes the existing honest
    not-found recovery.
  - Valid explicit and historical fallback reorders return `true` and retain
    the existing destination, Cart and acknowledgement behaviour.
  - Focused session verification passed 17/17.
  - Two same-source affected Buy regressions passed 94/94 each.
  - Founder-final Buy reference, customer-copy, interaction-contract,
    approved-lock, brand-integrity and protected-Social gates passed. The
    protected Social tree remained
    `54851b4769c6a0087f586ce6c9325bbee1d7c790e06488eccae3a62ca953332e`.
  - R24 was built with versionCode `2026073024`, installed on connected OPPO
    CPH2375, and replayed through Orders > Delivered > `MS-240741` card body.
    Cart opened with exactly the two Shop products at `₹316`; the isolated
    replay recorded no app fatal exception or ANR.
  - Candidate and pulled installed-base SHA-256 both equal
    `A77A391821E3552EEA98A2AE16DAE0E895BFB230214E2D565644A1FDA4F0D4FB`.
  - Durable evidence:
    `artifacts/quality/buy-post-r19-reorder-integrity-20260730-14`.

### `BUY-FV2-058` — Contract-test cart fulfilment and order projection

- Status: **COMPLETED 2026-07-30**
- Severity: **P1 regression-prevention coverage**
- Proven gap: the session suite checked scoped checkout and one exact Shop
  reorder, but did not assert the complete mixed-vertical projection from cart
  lines into seller-separated fulfilment groups and newly confirmed orders.
  A future change could therefore drift quantities, totals, seller ownership,
  product IDs or vertical order prefixes without a focused contract failure.
- Scope: production contract tests only. Application behaviour, UI, copy,
  layout, HTML, backend and Social remain unchanged.
- Acceptance:
  1. A mixed Shop, Wholesale and eligible Medicine cart is partitioned by the
     existing destination-plus-seller boundary.
  2. Every fulfilment group preserves exact line IDs, item counts, totals,
     partner metadata and destination; group sums equal checkout sums.
  3. Confirmation creates one uniquely identified order per group with the
     established vertical prefix, exact product IDs and exact totals.
  4. Confirmation totals/counts match the checkout snapshot and confirmed
     lines are removed once.
  5. Focused tests, two same-source affected regressions, OPPO replay,
     checksum proof and all protected gates pass.

- Production result:
  - Added a mixed-vertical session contract that derives expected
    destination-plus-seller groups from exact checkout lines, then proves
    product IDs, quantities, totals, partner metadata and aggregate sums.
  - The same contract proves confirmation emits one unique, correctly prefixed
    order per group, retains exact totals and product IDs, and removes the
    confirmed cart lines exactly once.
  - Focused session verification passed 18/18; full analysis passed.
  - Two same-source affected Buy regressions passed 95/95 each.
  - Founder-final Buy reference, customer-copy, interaction-contract,
    approved-lock, brand-integrity and protected-Social gates passed. The
    protected Social tree remained
    `54851b4769c6a0087f586ce6c9325bbee1d7c790e06488eccae3a62ca953332e`.
  - The unchanged R24 candidate was replayed on connected OPPO CPH2375 with
    two Shop sellers. Review order showed separate `₹37` and `₹279`
    fulfilment groups at aggregate `2 products · ₹316`; confirmation produced
    `MS-NEW-01` and `MS-NEW-02` for the correct partners. No app fatal
    exception or ANR occurred.
  - Candidate and device-computed installed SHA-256 both equal
    `A77A391821E3552EEA98A2AE16DAE0E895BFB230214E2D565644A1FDA4F0D4FB`.
  - Durable evidence:
    `artifacts/quality/buy-post-r19-checkout-contracts-20260730-15`.

### `BUY-FV2-059` — Fail closed on unsupported payment identifiers

- Status: **COMPLETED 2026-07-30**
- Severity: **P1 checkout state-integrity defect**
- Proven defect: the production payment sheet exposes only `UPI`,
  `Bank transfer` and `Purchase order`, while `choosePayment` accepted any
  arbitrary string and surfaced it as selected checkout state.
- Scope: validate the session input against the exact already-rendered payment
  choices. Payment processing, UI, copy outside the rejection result, HTML,
  backend and Social remain unchanged.
- Acceptance:
  1. The three established payment identifiers remain selectable.
  2. An unsupported or injected identifier returns `false`, preserves the
     existing payment selection and reports an honest unavailable result.
  3. Address selection remains independent from valid and rejected payment
     changes.
  4. Focused tests, two same-source affected regressions, known-path OPPO
     payment replay, exact candidate checksum proof and all protected gates
     pass.

- Production result:
  - Added the exact production-sheet allowlist (`UPI`, `Bank transfer`,
    `Purchase order`) to `BuyV2Session`.
  - `choosePayment` now returns `false` for an unsupported identifier,
    preserves the prior method and address, and reports that the method is not
    available. Established choices retain their existing behavior.
  - Focused session verification passed 19/19; full analysis passed.
  - Two same-source affected Buy regressions passed 96/96 each.
  - Founder-final Buy reference, customer-copy, interaction-contract,
    approved-lock, brand-integrity and protected-Social gates passed. The
    protected Social tree remained
    `54851b4769c6a0087f586ce6c9325bbee1d7c790e06488eccae3a62ca953332e`.
  - R25 versionCode `2026073025` was installed on connected OPPO CPH2375.
    The payment sheet exposed exactly the three allowed methods and no
    `Card`; selecting `Bank transfer` returned to Review order with
    `Payment · Bank transfer`. No app fatal exception or ANR occurred.
  - Candidate and device-computed installed SHA-256 both equal
    `2CF071BB363D477908649C52835692BEE5403838C71A07690E203175670E8DB5`.
  - Durable evidence:
    `artifacts/quality/buy-post-r19-payment-allowlist-20260730-16`.

### `BUY-FV2-060` — Establish a stable Buy identity and search hierarchy

- Status: **COMPLETED — R27 CHECKSUM-MATCHED OPPO VERIFIED 2026-07-30;
  FOUNDER ACCEPTANCE PENDING**
- Severity: **P0 founder-review production-design defect**
- Founder finding: across Shop, Wholesale, Medicine and Orders the wordmark,
  address / destination, search, scanner and account are too tightly packed.
  Search is compressed between unrelated product-grid actions and does not
  have the readable, screen-adaptive prominence seen in the approved market
  references.
- Scope: shared native Flutter Buy header and search hierarchy only. Preserve
  routes, query behaviour, scanner behaviour, account behaviour, catalogue
  data, the three-column grid, approved HTML, Screens 01–03 and Social.
- Acceptance:
  1. Shop, Wholesale, Medicine and Orders use one stable top order: compact
     MoolSocial identity plus location / context and account, followed by a
     dedicated rounded search band.
  2. Search receives the dominant horizontal budget and a minimum 48-logical-
     pixel target on 320, 360, 390 and 430 logical-pixel widths.
  3. Scanner stays at the search trailing edge and opens the established native
     camera / barcode flow; Category, Saved and More no longer reduce search
     width.
  4. The full `MoolSocial` semantic label remains available even when the
     visual brand mark is compact.
  5. Search and account remain keyboard / semantics accessible at 140% text
     scaling with no overflow.
  6. Focused analysis and tests pass before `BUY-FV2-061` starts.
- Completion:
  - The shared native header now uses a compact M watermark tile and keeps the
    complete brand name visible in the adjacent context label:
    `MoolSocial · Deliver to`, `MoolSocial · Buying for`,
    `MoolSocial · Licensed pharmacy`, `MoolSocial · Purchases` and
    `MoolSocial · Your account`.
  - The first R26 device candidate is preserved as rejected evidence because
    its compact wordmark clipped to `MoolSo` on the OPPO. R27 corrects that
    proven defect without enlarging the header or reducing search width.
  - Shop, Wholesale and Medicine expose their established scanner at the
    trailing edge of the dedicated search band. Orders uses search without a
    scanner because no order-scanner contract exists.
  - Account access was replayed from the shared header and opens the established
    account surface without leaving the Buy dock.

### `BUY-FV2-061` — Add responsive discovery and MoolSocial promotion

- Status: **COMPLETED — R27 CHECKSUM-MATCHED OPPO VERIFIED 2026-07-30;
  FOUNDER ACCEPTANCE PENDING**
- Severity: **P0 founder-review production-design defect**
- Founder finding: category access is visually weak and unprofessional when
  opened, while the Buy entry states provide no well-spaced MoolSocial product
  or service promotion. Product and order visibility must remain useful on
  every supported phone.
- Scope: a shared shallow category / contextual-action strip and compact,
  first-party promotion cards wired only to established native Buy actions.
  No ad backend, tracking contract, discount, external creative, inventory
  rule or new business promise may be invented.
- Acceptance:
  1. Shop, Wholesale and Medicine expose a horizontal, touch-safe discovery
     strip whose selected category is clear and whose choice updates the
     existing category filter.
  2. Saved and filter / sort stay reachable without consuming search width.
  3. Each vertical has independently configured MoolSocial-owned promotion
     copy and actions using only existing routes / session actions.
  4. Promotion scrolls with content and does not permanently occupy the product
     viewport. Orders places active-order content before continuation
     promotion.
  5. The existing three-column product grid remains intact, and at least one
     complete product row or order card is visible at 320 × 568 with 140% text
     scaling and no overflow.
  6. Focused analysis, navigation, category, copy and responsive tests pass
     before `BUY-FV2-062` starts.
- Completion:
  - Shop, Wholesale and Medicine use a shallow horizontal discovery rail with
    selected-state semantics; Saved and tools remain pinned outside the
    scrolling category choices.
  - MoolSocial-owned continuation cards use only existing native routes:
    monthly household basket and Wholesale from Shop, flexible restocking and
    Shop from Wholesale, prescription centre and no-prescription wellness from
    Medicine. Orders keeps active-order cards before continuation promotion.
  - The category replay selected `Fruits & vegetables` and immediately filtered
    the three-column grid. The monthly-basket promotion opened the established
    household-basket action.
  - The 64-image responsive matrix covers 320 × 568, 320 × 568 at 140% text,
    360 × 800, 390 × 844 iOS-size and 430 × 932 iOS-size states across the
    complete Buy journey.

### `BUY-FV2-062` — Make the active cart prominent and reachable

- Status: **COMPLETED — R27 CHECKSUM-MATCHED OPPO VERIFIED 2026-07-30;
  FOUNDER ACCEPTANCE PENDING**
- Severity: **P0 founder-review conversion and navigation defect**
- Founder finding: the current cart is too visually silent for a buyer's focus
  action. The preferred direction is the clear rounded conversion treatment
  observed in the preserved Zepto reference, adapted to MoolSocial's own
  tricolour design and established cart rules.
- Scope: the existing native Flutter non-empty cart affordance and its
  visibility rules. Do not change cart data, totals, vertical ownership,
  checkout, pricing, inventory, payment or fulfilment rules.
- Acceptance:
  1. A non-empty cart presents a rounded, high-contrast card above the Buy dock
     with item count, destination context, total and an explicit `View cart`
     action.
  2. The cart card is reachable from Shop, Wholesale, Medicine and Orders when
     items exist; it remains absent from checkout, account and unrelated
     tertiary tasks.
  3. The card is not obscured by safe areas, keyboard or bottom navigation and
     remains usable at 320–430 logical pixels and 140% text scaling.
  4. Opening the card preserves the correct established cart scope and back
     path for every originating destination.
  5. All prior cart, checkout, order, Medicine and destination-isolation
     contracts remain unchanged.
  6. Focused tests, two same-source full affected Buy regressions, protected
     gates, checksum-matched OPPO installation and complete four-destination
     replay pass before the group is marked complete.
- Completion:
  - A native high-contrast cart card now reports context, item count and total
    with an explicit `View cart` action above the Buy dock.
  - Live OPPO replay added Fresh tomatoes and proved
    `Shop cart · 1 item · ₹37` opened the Shop-scoped cart. Orders then proved
    `All carts · 1 item · ₹37` opened the aggregate cart.
  - The responsive total/action row no longer wraps at 320 × 568 with 140% text.
  - Full analysis passed, the focused screen suite passed 38/38, and two
    same-source affected Buy regressions passed 102/102 each against source
    fingerprint
    `DBB4BBA084FC5522E30B7AF51952A9A3BE637378DD7897D5D9B15D772EBE22EC`.
  - Founder-FINAL Buy reference, customer-copy, interaction-contract,
    approved-lock, brand-integrity and protected-Social gates passed. The
    protected Social tree remained
    `54851b4769c6a0087f586ce6c9325bbee1d7c790e06488eccae3a62ca953332e`.
  - R27 versionCode `2026073027` was installed on OPPO CPH2375. The candidate,
    device-computed package and pulled installed base all share SHA-256
    `8192B002A7F0372CC3A10872A26C498D0DC4E28FA3AF5531453A0B0528679BFF`.
    Durable evidence:
    `artifacts/quality/buy-flutter-r27-market-brand-oppo-20260730-20`.

### `BUY-FV2-063` — Correct the compact M watermark proportions

- Status: **COMPLETED — CHECKSUM-MATCHED R28 OPPO VERIFIED 2026-07-30**
- Severity: **P0 founder-review brand-integrity defect**
- Founder finding: the R27 compact M watermark appears squeezed and corrupted
  on the real OPPO.
- Proven cause: the mark was painted into a portrait `24 × 30` box, producing
  a `0.8` aspect ratio that compressed a naturally wide M silhouette.
- Scope: the code-native M watermark geometry and its focused regression test
  only. Preserve the existing 50 × 44 header tile, complete contextual
  `MoolSocial` naming, search width, account target, all Buy logic, approved
  HTML, Screens 01–03 and Social.
- Acceptance:
  1. The watermark uses a landscape proportion of at least `1.3` without
     enlarging the header tile.
  2. Left and right strokes, peaks, centre joint and coloured dots are balanced
     and remain inside the paint bounds.
  3. `MoolSocial · ...` remains fully visible at 320 logical pixels and 140%
     text scaling.
  4. Focused tests, two same-source affected Buy regressions, protected gates
     and checksum-matched R28 OPPO replay pass.
- Verification:
  - The mark now paints into a landscape `32 × 24` box inside the unchanged
    50 × 44 header tile. The focused test locks the exact size and a minimum
    `1.3` aspect ratio.
  - The complete `MoolSocial · ...` context remained visible on the OPPO and
    in the 320 logical pixel / 140% text fitment test.
  - Final R28 source fingerprint
    `E080C090A18C97800D89381D93AC25815027E9EE2CF15160FE8DD493C32A31FD`
    passed analysis, the 39/39 focused screen suite and both 103/103
    same-source affected regressions.
  - The final candidate and pulled OPPO package share SHA-256
    `D3813583A90D102B51C9001AC15638710D93E727EA1A4337023EFF3919E95A8F`.

### `BUY-FV2-064` — Replace long sideways category discovery

- Status: **COMPLETED — CHECKSUM-MATCHED R28 OPPO VERIFIED 2026-07-30**
- Severity: **P0 founder-review product-discovery defect**
- Founder finding: the R27 horizontal category rail requires too much left/right
  scrolling before a buyer can reach the desired category. The replacement
  should use the compact, direct interaction quality associated with WeChat.
- Scope: Shop, Wholesale and Medicine category presentation only. Preserve the
  established category IDs, filters, products, three-column grid, Saved, tools,
  search, cart and all vertical isolation.
- Acceptance:
  1. The resting catalogue uses one stable current-category control and no
     horizontal category rail.
  2. Opening the control presents a compact multi-column category panel with a
     local category search; no backend search contract is invented.
  3. One category tap selects, closes the panel and restores the full product
     grid.
  4. A buyer can directly find later categories such as `Shop supplies` without
     repeated sideways scrolling.
  5. The panel adapts to two columns on compact phones and three columns on
     wider phones, remains usable at 140% text and preserves reduced-motion
     behaviour.
  6. Focused tests, responsive evidence, two same-source affected Buy
     regressions, protected gates and checksum-matched R28 OPPO replay pass.
- Verification:
  - The horizontal rail is absent. A stable current-category control opens a
    vertically scrolling, searchable two/three-column panel without changing
    any category ID, filter or vertical contract.
  - The first device replay proved that horizontal icon/label tile composition
    still truncated names such as `Best prices` and split Medicine labels.
    That unaccepted evidence is preserved. The final tile uses the compact
    icon-above-centred-label pattern and keeps the complete labels readable.
  - OPPO replay verified Shop, Wholesale and Medicine panels, direct local
    search for `Shop supplies`, one-tap selection and automatic panel close.
  - Sixty-five new Android/iOS-size and 140%-text captures use the
    `buy-v2-r28-category-tile-fix-local-*` prefix so earlier R28 captures were
    not overwritten.

### `BUY-FV2-065` — Keep Saved complete after category selection

- Status: **COMPLETED — CHECKSUM-MATCHED R28 OPPO VERIFIED 2026-07-30**
- Severity: **P1 functional product-retrieval defect**
- Proven finding: selecting a late category and then opening Saved inherited
  that category, which could hide saved products belonging to other categories.
- Scope: native Saved-entry state only; preserve saved ownership by vertical
  and every established product/category identifier.
- Acceptance:
  1. Opening Saved resets the category lens to that vertical's `all` category.
  2. Every saved product for the active vertical is visible.
  3. Closing Saved returns to the established product catalogue without
     cross-vertical leakage.
  4. Focused and full affected regressions pass.
- Verification:
  - Opening Saved after selecting `Shop supplies` resets the Shop category lens
    to `For you` and restores all three saved Shop products.
  - Focused regression coverage locks this transition; both final 103/103
    affected regression cycles passed against the same R28 fingerprint.
  - No product identifier, category identifier or cross-vertical ownership
    rule changed.

### `BUY-FV2-066` — Reduce the resting category control to one compact action

- Status: **IMPLEMENTED — R29 DEVICE VERIFIED 2026-07-30**
- Severity: **P0 founder-review catalogue-space defect**
- Founder finding: the current category control occupies nearly a full row and
  competes with promotions, useful catalogue content and the product grid.
- Scope: the resting category launcher shared by Shop, Wholesale and Medicine.
  Preserve the selected category state and existing category contracts.
- Acceptance:
  1. The resting launcher is one clear 44-pixel-or-larger menu/category action,
     not a long category bar.
  2. Its accessible label announces the active vertical and category.
  3. The reclaimed width remains available to established MoolSocial
     promotions/features and catalogue content without inventing advertising
     contracts.
  4. The action remains reachable at 320 logical pixels and 140% text.

### `BUY-FV2-067` — Compact and anchor the category panel above the Buy dock

- Status: **IMPLEMENTED — R29 DEVICE VERIFIED 2026-07-30**
- Severity: **P0 founder-review modal-space defect**
- Founder finding: the R28 panel spends too much height on the title,
  explanatory copy and large search field, and visually detaches from the
  bottom navigation.
- Scope: Shop, Wholesale and Medicine category-panel presentation only.
- Acceptance:
  1. Remove the `Shop/Wholesale/Medicine categories` title and explanatory
     paragraph from the visible panel.
  2. Keep one smaller `Find a category` field and move the close action outside
     the field.
  3. The panel starts immediately above the persistent Buy dock and consumes no
     unnecessary lower gap.
  4. The surface uses a restrained white/glass brand treatment that keeps
     background products perceptible while category labels retain accessible
     contrast.
  5. Search, selection, close, outside dismissal and reduced-motion behaviour
     remain honest and deterministic.

### `BUY-FV2-068` — Use category-specific, legible iconography

- Status: **IMPLEMENTED — R29 DEVICE VERIFIED 2026-07-30**
- Severity: **P1 product-discovery comprehension defect**
- Founder finding: abstract glyphs do not consistently communicate the
  category they represent.
- Scope: code-native category presentation; no downloaded image, HTML asset or
  backend field.
- Acceptance:
  1. Every Shop, Wholesale and Medicine category maps to a semantically fitting
     Material icon or an explicit, tested fallback.
  2. Icons remain distinct from labels, visible on glass/white surfaces and
     compatible with the brand palette.
  3. Category IDs, filters and vertical isolation do not change.

### `BUY-FV2-069` — Make repeated owner-action taps return to the prior screen

- Status: **IMPLEMENTED — R29 DEVICE VERIFIED 2026-07-30**
- Severity: **P1 navigation muscle-memory defect**
- Founder finding: tapping the DC account owner opens Account, but tapping the
  same DC owner again while Account is open does not close it.
- Scope: repeated taps on persistent Buy owner/actions whose opened state
  remains visibly available; preserve system Back and route history.
- Acceptance:
  1. Account owner tap opens Account and the same owner tap closes it back to
     the exact prior Buy state.
  2. Repeated active Saved/search/category actions close their owned transient
     state where the same control remains available.
  3. Bottom-destination taps remain deterministic and never create route loops
     or exit the Buy module unexpectedly.
  4. The protected Social/YouTube implementation remains unchanged.

### `BUY-FV2-070` — Replace product `ADD` text with inline quantity steppers

- Status: **IMPLEMENTED — R29 DEVICE VERIFIED 2026-07-30**
- Severity: **P0 purchase-effort defect**
- Founder finding: product cards require an `ADD` action and quantity reduction
  is deferred to Cart instead of being available at the product interaction.
- Scope: existing native Shop, Wholesale and Medicine cart/session contracts
  and their product/cart presentation.
- Acceptance:
  1. Quantity zero presents one clear `+` action instead of `ADD`.
  2. Quantity above zero presents `− quantity +` on the product card.
  3. `+` adds one and `−` removes one; reaching zero removes the line through
     the established session operation.
  4. Cart exposes the same quantity controls and recomputes vertical/aggregate
     counts and totals through existing production logic.
  5. Controls have 44-pixel tap targets, correct semantics and singular/plural
     customer copy.

### `BUY-FV2-071` — Make shared Buy search compact at rest and expansive in use

- Status: **IMPLEMENTED — R29 DEVICE VERIFIED 2026-07-30**
- Severity: **P0 responsive hierarchy defect**
- Founder finding: the search field is a permanently large fixed box instead
  of adapting to user intent and screen width.
- Scope: shared Buy search entry for Shop, Wholesale, Medicine and Orders using
  existing local search/query behaviour.
- Acceptance:
  1. Resting search is compact and leaves useful horizontal/vertical space.
  2. Tapping it expands a real editable search owner without overflow or
     content jump; close/clear returns it to the compact state.
  3. Search result, empty and recovery contracts remain unchanged.
  4. The control fits representative Android/iOS phone widths and 140% text.

### `BUY-FV2-072` — Restore MoolSocial brand-mark contrast

- Status: **IMPLEMENTED — R29 DEVICE VERIFIED 2026-07-30**
- Severity: **P0 founder-review brand-legibility defect**
- Founder finding: blue portions of the M mark lose legibility against the
  dark-blue tile/background.
- Scope: the shared native Buy mark container only; preserve the approved mark
  geometry, tricolour accents and complete contextual `MoolSocial` name.
- Acceptance:
  1. The mark receives a neutral/light backing that separates both blue and
     orange strokes from the surrounding navy header.
  2. The balanced `32 × 24` R28 proportions remain unchanged.
  3. Brand, 320-pixel/140%-text and protected-reference gates pass.

### `BUY-FV2-073` — Enforce R29 behaviour across every owned Buy surface

- Status: **IMPLEMENTED — R29 DEVICE VERIFIED 2026-07-30**
- Severity: **P0 cross-vertical consistency gate**
- Founder direction: the compact category, adaptive search, quantity, repeated
  action and brand corrections must not be isolated to Shop.
- Scope: Shop, Wholesale, Medicine, Orders, product detail, Cart and the Buy
  dock/Chat hand-off. Protected Social/YouTube and unowned Chat internals remain
  frozen.
- Acceptance:
  1. Shared controls behave consistently wherever their owner is present.
  2. Vertical-specific search, category and cart rules remain independently
     configurable.
  3. Cart and tertiary screens retain low-effort Back/owner navigation.
  4. The Buy dock still opens the established Chat owner without modifying the
     protected Social tree.
  5. Focused tests, responsive evidence, two same-source full regressions,
     protected gates and checksum-matched OPPO replay pass.

R29 verification:

- Final 28-file source fingerprint:
  `B7911CDD3D770F3E7260C18B7B2388E92C59819A266147CBF4D70E248E54CCCB`.
- Full Flutter analysis, corrected focused Buy suite `84/84`, responsive
  capture generation/replay `2/2`, and 73 final responsive images passed.
- Two complete regressions passed independently at `113/113` against that
  same fingerprint; the post-device fingerprint remained identical.
- Founder-FINAL Buy reference, customer-copy, 154-route interaction, approved
  UI lock, brand, Git-diff and protected Social gates passed.
- Exact R29 candidate and pulled OPPO installed APK share SHA-256
  `3136A7CFA4EB1C3A001422F18C8C49CF1CE775F673EA68EFF71BC1D4956918CD`.
- Checksum-matched OPPO replay covered Shop, category glass, adaptive search,
  scanner, product/cart quantity, Account return, Wholesale, Medicine,
  prescription, Orders, tracking and Chat exact-return behaviour.
- Durable handoff:
  `docs/quality/BUY-V2-R29-COMPACT-COMMERCE-HANDOFF-20260730.md`.
- Evidence:
  `artifacts/quality/buy-flutter-r29-compact-commerce-oppo-20260730-22`.

Founder visual acceptance, commit, push, deploy, publication and production
release remain pending.

## Founder review after R29 — iteration approval and R30 direction

Founder decision recorded 30 July 2026:

- R29 is approved as the current Buy UI/UX **iteration baseline**, subject to
  the proven mixed-cart defect and the explicitly requested R30 motion, theme,
  brand-identity, live-product, promotion, advertising and partner-language
  work below.
- This is not an immutable final reference, production release acceptance,
  backend-start authorization, commit, push, deploy or publication approval.
- The next Buy implementation session is UI/UX-first. Do not begin the Buy
  backend before the R30 presentation direction and applicable data contracts
  have completed founder review.
- Do not modify the founder-FINAL Buy HTML `v1`. Any new HTML authority, if
  required by the approved-reference workflow, must be a new version and a new
  founder-review cycle.

### `BUY-FV2-074` — Make Cart entry aggregate and consistent across all Buy verticals

- Status: **R36 CHECKSUM-MATCHED OPPO VERIFIED — FOUNDER COMBINED REVIEW
  PENDING 2026-07-31**
- Severity: **P0 purchase-state consistency defect**
- Founder finding: adding from Shop appears to behave as a separate Cart path
  from Wholesale and Medicine.
- Current implementation fact: the session has one cart-line collection but
  exposes `all`, `shop`, `wholesale` and `medicine` scopes. Several entry
  points deliberately open a vertical scope, which can make one family appear
  isolated even while other lines remain stored.
- Scope: Cart entry, compact Cart action, vertical additions, Cart scope bar,
  checkout projection and exact return navigation.
- Acceptance:
  1. Adding from Shop, Wholesale or Medicine preserves every existing line and
     updates one aggregate Cart state.
  2. The primary Cart action opens the aggregate Cart by default; an optional
     family filter may inspect Shop, Wholesale or Medicine without becoming a
     separate basket or hiding that other families exist.
  3. Aggregate quantity, total and family counts update identically after an
     add, increase, decrease or removal from any vertical.
  4. Family-specific fulfilment, prescription and checkout requirements remain
     visibly separated inside the one aggregate order review.
  5. Opening Cart and returning restores the exact prior product, catalogue or
     tertiary state.
  6. Mixed Shop + Wholesale + Medicine device tests prove that no vertical
     replaces, strands or silently filters another.

### `BUY-FV2-075` — Replace customer-visible `Verified` with a role-based Mool partner language

- Status: **R36 ROLE GLOSSARY IMPLEMENTED AND OPPO VERIFIED — FOUNDER
  COMBINED REVIEW PENDING 2026-07-31**
- Severity: **P0 trust-language and brand-positioning defect**
- Founder finding: repeated `Verified retailer/shop/wholesaler/manufacturer`
  wording feels cheap and less trustworthy. The customer should understand
  what each business actually does and its relationship with MoolSocial.
- Inventory finding: Buy currently contains 103 `Verified` match lines across
  six production files. Catalogue data includes retailer, shop, wholesaler,
  distributor and manufacturer roles; Medicine also carries real licensed-
  pharmacy facts.
- Scope: customer-visible terminology across Buy first, then a separately
  authorized module-by-module application-wide audit covering retailer, shop,
  salon, clinic/hospital, wholesaler, distributor, manufacturer, pharmacy and
  service-provider surfaces. Protected Social remains frozen until separately
  authorized.
- Acceptance:
  1. Remove customer-visible standalone `Verified` and `VERIFIED` badges; do
     not perform a blind code-wide replacement.
  2. Establish one concise role glossary based on what the party actually
     provides. Candidate families for founder selection include `Mool retail
     partner`, `Mool trade partner`, `Mool pharmacy partner`, `Mool
     manufacturer partner`, `Mool service partner` and `fulfilment partner`.
     These are proposals, not approved final copy.
  3. Preserve precise regulatory or safety facts such as licensed pharmacy,
     medical registration, identity check or applicable business credentials
     where they are true and contractually supported.
  4. Never imply MoolSocial endorsement, certification, guarantee or licensing
     unless the corresponding production contract and evidence exist.
  5. The final glossary must distinguish commercial role, fulfilment role and
     regulatory status rather than collapsing them into one generic badge.
  6. Founder approves the glossary before application code, data fixtures,
     accessibility labels, tests or new reference assets are changed.

### `BUY-FV2-076` — Establish the shared R30 Buy motion and state-acknowledgement system

- Status: **R36 FINITE MOTION SYSTEM CHECKSUM-MATCHED OPPO VERIFIED —
  FOUNDER COMBINED REVIEW PENDING 2026-07-31**
- Severity: **P0 cross-surface interaction-language requirement**
- Founder direction: every Buy state and action should feel live, responsive
  and visibly acknowledged.
- Scope: Shop, Wholesale, Medicine, Orders, Cart, Checkout, address, account,
  tracking, product detail, prescription and Buy Chat hand-off.
- Acceptance:
  1. Define motion tokens for tap acknowledgement, selection, add/remove,
     expand/collapse, route transition, progress, success, recovery and return.
  2. Motion communicates real state change and never introduces fake waiting,
     perpetual loading or progress disconnected from work.
  3. Repeat actions cannot double-submit while an asynchronous operation is
     active.
  4. Reduced-motion behaviour preserves acknowledgement with opacity, colour,
     static progress or concise status text.
  5. Motion timing, easing and ownership are shared, but vertical-specific
     presentation remains independently configurable.

### `BUY-FV2-077` — Create responsive screen-type and vertical themes under the Indian tricolour

- Status: **R36 RESPONSIVE THEME SYSTEM CHECKSUM-MATCHED OPPO VERIFIED —
  FOUNDER COMBINED REVIEW PENDING 2026-07-31**
- Severity: **P1 thematic hierarchy requirement**
- Founder direction: screen themes should change meaningfully based on the Buy
  screen or vertical while remaining recognisably MoolSocial.
- Scope: Shop, Wholesale, Medicine, Orders, Cart/Checkout, tracking, account
  and Assist theme tokens; no hard-coded page-by-page palette forks.
- Acceptance:
  1. Establish a shared MoolSocial foundation using an accurate Indian
     tricolour relationship, accessible navy/neutral anchors and semantic
     success, warning and error colours.
  2. Give each vertical or screen family a distinct but related theme without
     changing product facts, navigation ownership or business rules.
  3. Theme transitions are purposeful and do not flash, impair text contrast,
     recolour regulatory states ambiguously or compete with product content.
  4. Light/dark surfaces, Android/iOS sizes, 140% text, reduced transparency
     and high-contrast cases are specified before implementation.
  5. Brand-integrity and customer-copy gates remain authoritative.

### `BUY-FV2-078` — Build an unmistakable animated MoolSocial identity

- Status: **R36 CODE-NATIVE IDENTITY CHECKSUM-MATCHED OPPO VERIFIED —
  FOUNDER COMBINED REVIEW PENDING 2026-07-31**
- Severity: **P0 brand-recognition requirement**
- Founder finding: the current M mark does not read as a convincing tricolour
  identity and does not always tell the customer that the product is
  MoolSocial.
- Scope: code-native Buy brand mark/wordmark motion and its compact/resting
  states; do not alter the protected Social implementation.
- Acceptance:
  1. Correct the mark's saffron, white/neutral, green and navy relationship
     without distorting the approved M geometry.
  2. At an appropriate first-entry or contextual moment, motion reveals or
     reinforces the complete `MoolSocial` name; the customer is never left
     with an unexplained M watermark.
  3. Resting headers remain compact after recognition and do not steal
     catalogue space.
  4. Animation is code-native or uses an approved production asset, has a
     static reduced-motion state and never loops merely for decoration.
  5. The mark stays crisp and proportionate across Android/iOS density,
     orientation and text-scale cases.

### `BUY-FV2-079` — Introduce a restrained 3D commerce interaction language

- Status: **R36 RESTRAINED DEPTH SYSTEM CHECKSUM-MATCHED OPPO VERIFIED —
  FOUNDER COMBINED REVIEW PENDING 2026-07-31**
- Severity: **P1 depth, touch and product-presence requirement**
- Founder direction: Buy should gain professional 3D motion, liveliness and a
  more happening product experience.
- Scope: product cards, category owner, promotions, Cart, order status,
  tracking and selected tertiary surfaces.
- Acceptance:
  1. Define where elevation, parallax, perspective, object rotation, layered
     cards or spatial transitions improve comprehension.
  2. 3D effects respond to user intent or state and never reduce tap accuracy,
     product legibility, price visibility or grid density.
  3. No copied marketplace animation, deceptive depth, motion sickness pattern
     or GPU-heavy perpetual scene is allowed.
  4. Static fallback, reduced motion, low-power mode and low-end-device
     behaviour are specified.
  5. Product cards retain stable bounds so motion cannot cause accidental adds
     or shifting purchase controls.

### `BUY-FV2-080` — Keep live product information active inside stable product tiles

- Status: **R36 REPLACEABLE FACTS CONTRACT AND FALLBACK VERIFIED — REAL
  PROVIDER SELECTION REMAINS DEFERRED 2026-07-31**
- Severity: **P0 live-commerce information requirement**
- Founder direction: product tiles should stay alive by presenting changing
  product information within the grid.
- Scope: existing product-tile facts and future replaceable live-data adapter;
  no invented production API or database field.
- Acceptance:
  1. Identify the established facts allowed to update, such as price,
     availability, delivery estimate, seller/partner, offer or orderability.
  2. Dynamic facts update in a fixed tile region without changing card height,
     moving `+ / −`, hiding price or causing grid reflow.
  3. Every change has a timestamp/source contract, deterministic stale state
     and non-animated reduced-motion presentation.
  4. Cycling pauses when off-screen, during touch exploration or when the
     customer focuses a control.
  5. Production code cannot simulate live values. Test fixtures and preview
     adapters remain explicitly non-production.

### `BUY-FV2-081` — Add first-party MoolSocial promotion modules

- Status: **R36 FIRST-PARTY PROMOTION FOUNDATION OPPO VERIFIED — FOUNDER
  COMBINED REVIEW PENDING 2026-07-31**
- Severity: **P1 discovery and first-party merchandising requirement**
- Founder direction: reclaimed commerce space should promote useful
  MoolSocial products, services and established Buy features.
- Scope: responsive first-party cards in Shop, Wholesale, Medicine, Orders and
  appropriate Cart/Checkout moments.
- Acceptance:
  1. Each card solves a clear customer problem and opens an established,
     production-owned destination.
  2. Cards are distinguishable from product tiles and paid advertising.
  3. Rotation or motion never displaces the primary product row or purchase
     controls after the customer begins interacting.
  4. Empty, unavailable and reduced-motion states remain useful and compact.
  5. No promotion invents a route, entitlement, service, price or backend
     capability.

### `BUY-FV2-082` — Define transparent sponsored and other advertisement placements

- Status: **R36 FAIL-CLOSED SPONSORED-CONTENT CONTRACT VERIFIED — ACTIVATION
  REMAINS UNAUTHORIZED 2026-07-31**
- Severity: **P0 advertising trust and layout requirement**
- Founder direction: Buy should support advertisement cards and other
  advertising formats without losing healthy product space.
- Scope: placement, disclosure, interaction and adapter boundaries only until
  commercial, moderation, measurement and API contracts are approved.
- Acceptance:
  1. Define eligible surfaces, density limits, frequency caps and product-grid
     protection for every ad format.
  2. Paid content is unmistakably labelled and never resembles an organic
     seller, system status or MoolSocial recommendation.
  3. Ads cannot cover Cart, price, quantity, prescription, delivery, payment or
     safety information.
  4. Dismissal, report/feedback, accessibility and failure/empty behaviour are
     specified.
  5. Use a replaceable ad adapter. No production mock response, invented
     campaign field or implied advertiser relationship is allowed.

### `BUY-FV2-083` — Design safe, performant inline video advertisements

- Status: **R36 VIDEO-AD CONTRACT VERIFIED — NO PLAYER OR PROVIDER ACTIVATED
  2026-07-31**
- Severity: **P0 video-ad accessibility and performance requirement**
- Founder direction: Buy should support video advertising as part of the more
  lively commerce experience.
- Scope: product-grid-adjacent and promotion-card video presentation; no
  provider/backend selection in this ticket.
- Acceptance:
  1. Video starts muted, never steals audio focus, pauses off-screen and has a
     visible play/pause owner.
  2. Captions/transcript, ad disclosure, poster fallback, reduced motion, data
     saver and low-bandwidth behaviour are mandatory.
  3. Video cannot shift the grid, block product actions, auto-open a
     destination or replay perpetually.
  4. Resource limits cover preloading, memory, battery, thermal and network
     use on representative low/mid-range devices.
  5. Click-through, measurement, consent and moderation contracts are defined
     before any production integration.

### `BUY-FV2-084` — Gate R30 motion, theme and advertising for accessibility and performance

- Status: **R36 AUTOMATED AND CHECKSUM-MATCHED DEVICE GATES RECORDED —
  RELEASE-HARDWARE FRAME PROFILING AND FOUNDER REVIEW REMAIN OPEN
  2026-07-31**
- Severity: **P0 production-readiness gate**
- Scope: every R30 motion, 3D, theme, dynamic tile, promotion and advertisement
  ticket.
- Acceptance:
  1. Establish frame-time, jank, memory, APK-size, thermal, network and battery
     budgets before implementation.
  2. Validate TalkBack order, focus stability, 44-pixel targets, contrast,
     140% text, reduced motion, reduced transparency and keyboard/switch use.
  3. Verify Android/iOS-size portrait and landscape layouts without product-
     grid reflow or unsafe-area clipping.
  4. Automated tests use deterministic time and animation control; no flaky
     screenshot or perpetual-ticker path remains.
  5. Device replay must include low-power, app-switch, interruption, process-
     death and restored-state cases relevant to animated surfaces.

### `BUY-FV2-085` — Complete R30 cross-surface founder review before Buy backend start

- Status: **R36 CONNECTED CANDIDATE READY — FOUNDER REVIEW REQUIRED; DO NOT
  CLOSE 2026-07-31**
- Severity: **P0 founder-review and sequencing requirement**
- Scope: Tickets `BUY-FV2-074` through `BUY-FV2-084`.
- Acceptance:
  1. One approved motion/theme/partner-language specification covers Shop,
     Wholesale, Medicine, Orders, Cart, Checkout, account, tracking and Buy
     Chat hand-off.
  2. The aggregate Cart defect and final partner-role glossary are resolved.
  3. Every dynamic/live/advertising surface has a clear replaceable data
     contract and can render an honest empty or unavailable state.
  4. Focused tests, two same-source Buy regressions, protected references,
     copy, brand, Social integrity, performance and checksum-matched OPPO
     replay pass.
  5. Founder reviews the complete connected R30 experience before backend
     implementation begins.

### `BUY-FV2-086` — Audit and repair every non-working Buy tap

- Status: **IMPLEMENTATION AUTHORIZED — R30 IN PROGRESS 2026-07-30**
- Severity: **P0 connected-journey wiring defect**
- Founder finding: some Buy screens and their deeper taps do not respond or do
  not open the expected owned destination.
- Scope: every visible action, sub-action and tertiary action in Shop,
  Wholesale, Medicine, Orders, Cart, Checkout, product detail, Account,
  tracking, prescription and Buy Chat hand-off.
- Acceptance:
  1. Build a semantic tap inventory from the actual native Flutter candidate,
     not only the approved HTML contract.
  2. Every enabled control produces one visible result, opens its named owner
     or explains honestly why the action is unavailable.
  3. Disabled controls cannot look enabled; repeated taps cannot duplicate an
     order, review, report, upload or navigation entry.
  4. Back and repeated-owner taps restore the exact previous state.
  5. Widget tests and connected-OPPO replay cover all repaired taps and record
     any still-blocked backend-dependent action separately.

### `BUY-FV2-087` — Build professional role-aware product detail pages

- Status: **IMPLEMENTATION AUTHORIZED — R30 IN PROGRESS 2026-07-30**
- Severity: **P0 product-understanding and purchase-confidence defect**
- Founder finding: current deeper product pages across retail, Wholesale,
  Medicine and Orders do not look or behave like professional complete product
  pages.
- Inspiration boundary: use the founder-captured Amazon screenshots only to
  study information order, spacing and stable purchase actions. Do not copy
  Amazon branding, colour, components, wording or interaction design.
- Acceptance:
  1. Lead with an original product image, complete product name, pack/variant,
     price/unit price, availability and delivery promise.
  2. Show the named Mool partner and exact commercial role appropriate to
     retail, trade, manufacturer or pharmacy fulfilment.
  3. Present role-aware specifications: consumer facts for Shop, MOQ/case/
     landed-cost and supply facts for Wholesale, and medicine/prescription/
     manufacturer facts for Medicine.
  4. Preserve price, quantity and primary purchase action in a stable,
     reachable area while the page scrolls.
  5. Orders can open the purchased item's frozen order-time facts without
     silently substituting the current catalogue product.
  6. The page fits representative Android/iOS sizes and 140% text without
     horizontal overflow or inaccessible actions.

### `BUY-FV2-088` — Show evidence-based partner trust and service performance

- Status: **IMPLEMENTATION AUTHORIZED — R30 IN PROGRESS 2026-07-30**
- Severity: **P0 trust and fulfilment-transparency requirement**
- Founder direction: replace cheap generic verification wording with useful
  trustworthiness factors such as timely delivery and product quality.
- Acceptance:
  1. Use the founder-agreed Buy glossary: `Mool Retail Partner`, `Mool Trade
     Partner`, `Mool Manufacturer Partner`, `Mool Pharmacy Partner` and
     `Fulfilment Partner`.
  2. Preserve a separate factual regulatory label such as `Licensed pharmacy`
     only when established by the current model.
  3. Trust factors must be based on established fields or explicitly local
     review aggregates. Do not invent certifications, guarantees or backend
     performance history.
  4. Eligible factors include on-time fulfilment, quality feedback, return/
     replacement terms, named business, order count or response history only
     where supported.
  5. Customer-facing `Verified`/`VERIFIED` is absent from every reachable Buy
     state, semantic label and test fixture.

### `BUY-FV2-089` — Add customer ratings, reviews and issue reporting

- Status: **IMPLEMENTATION AUTHORIZED — R30 IN PROGRESS 2026-07-30**
- Severity: **P0 customer-voice and recovery requirement**
- Scope: products fulfilled by retail, wholesale/distributor, manufacturer and
  pharmacy roles; current session owner first, replaceable backend adapter
  later.
- Acceptance:
  1. Product detail shows rating average, rating count and a concise review
     summary only from established local review data.
  2. Customers can open reviews and submit one rating/review through a
     deterministic session owner; repeat submission updates rather than
     duplicates the customer's review.
  3. `Report product or partner` opens a reason owner, records one report,
     acknowledges receipt and blocks accidental duplicate submission.
  4. Report reasons distinguish product quality, incorrect information,
     fulfilment, safety and prohibited content without making an unsupported
     finding.
  5. Review/report interfaces are replaceable and contract-tested. No fake API
     success, moderation promise or production persistence claim is allowed.
  6. Medicine reporting keeps safety wording factual and does not substitute
     medical advice or emergency support.

### `BUY-FV2-090` — Add original product imagery to grids and detail pages

- Status: **IMPLEMENTATION AUTHORIZED — R30 IN PROGRESS 2026-07-30**
- Severity: **P0 product-recognition requirement**
- Founder direction: each product tile needs a small real-looking product
  photo and product detail needs a useful larger image.
- Acceptance:
  1. Use original/licensed MoolSocial assets; never copy Amazon product photos
     or other marketplace assets.
  2. The grid uses a compact, consistently cropped image that preserves the
     three-column density and `+ / −` control.
  3. Detail uses a larger image with an honest fallback when an asset is
     unavailable.
  4. Asset attribution/licence or generated-origin evidence is recorded.
  5. Decode size, caching, memory, APK-size and low-end-device behaviour are
     measured; images never cause card reflow or touch-target movement.
  6. Accessibility names the product, not decorative packaging details.

### `BUY-FV2-091` — Open purchased item detail from Orders and tracking

- Status: **IMPLEMENTATION AUTHORIZED — R30 IN PROGRESS 2026-07-30**
- Severity: **P1 order-history comprehension defect**
- Scope: active and delivered Orders, tracking Items action and order-line
  taps.
- Acceptance:
  1. Every visible order line opens its order-time item detail.
  2. The page shows the purchased name, variant, quantity, paid price, partner,
     fulfilment family, order ID and applicable prescription/return facts.
  3. Stale or removed catalogue IDs fail closed with the recorded order-line
     facts rather than another current product.
  4. Review/report eligibility is clear for active versus delivered orders.
  5. Back returns to the exact Orders tab, order and scroll position.

### `BUY-FV2-092` — Prove the complete R30 product-detail journey across roles and devices

- Status: **IMPLEMENTATION AUTHORIZED — R30 QUALITY GATE**
- Severity: **P0 cross-role acceptance gate**
- Scope: Tickets `BUY-FV2-086` through `BUY-FV2-091`.
- Acceptance:
  1. Replay Shop retail, Wholesale trade/manufacturer, Medicine pharmacy/
     manufacturer and Orders item-detail journeys.
  2. Verify imagery, facts, partner role, trust factors, quantity, Cart,
     reviews, report, Back and repeated-owner actions.
  3. Test 320-pixel/140%-text, representative Android/iOS sizes, reduced
     motion and image-fallback states.
  4. Run focused tests after each logical change, then two unchanged-source
     complete Buy regressions and every protected gate.
  5. Install, checksum-match and replay the exact candidate on the connected
     OPPO before presenting it for founder review.

### `BUY-FV2-093` — Lead product discovery with a media-first collection and dominant detail gallery

- Status: **IMPLEMENTED AND DEVICE VERIFIED — FOUNDER REVIEW PENDING
  2026-07-30**
- Severity: **P0 product-discovery and media-hierarchy requirement**
- Founder direction: use the useful hierarchy observed in the current Zepto
  screenshots without copying Zepto branding, assets, copy or component
  styling. The default Buy landing should reveal products through a large
  image-led collection before the dense catalogue, and the next page should
  give product media clear priority.
- Scope: the shared native Flutter catalogue and product-detail surfaces for
  Shop, Wholesale and Medicine. Orders retains its established order-focused
  hierarchy.
- Acceptance:
  1. The unfiltered default landing shows first-party promotion cards followed
     by one horizontally browsable product-image collection before the dense
     multi-row catalogue.
  2. Search, a selected category and Saved products continue to open directly
     into the compact dense grid so task-focused customers do not repeat the
     discovery content.
  3. Product media uses original/generated MoolSocial-owned assets only.
     Products without a truthful exact image show an honest category visual;
     image decoding also has a non-blank, non-deceptive first-frame fallback.
  4. Product detail uses a responsive, dominant and multi-image-ready gallery.
     Count and paging controls appear only when more than one real media item
     exists.
  5. The `+` owner remains at least 44 pixels and changes in place to `− / +`
     quantity controls. Card bounds and purchase targets do not move during
     press or state acknowledgement.
  6. Shared motion tokens control press and state feedback, reduced-motion
     mode resolves transitions immediately, and no fake waiting or perpetual
     animation is introduced.
  7. The hierarchy fits 320-pixel/140%-text and representative Android/iOS
     portrait sizes, retains the aggregate Cart owner and passes the complete
     Buy regression and protected-reference gates.

### `BUY-FV2-094` — Give Buy search a complete responsive search-and-results owner

- Status: **IMPLEMENTED, AUTOMATED AND CHECKSUM-MATCHED R33.4 OPPO VERIFIED
  2026-07-30 — FOUNDER REVIEW PENDING**
- Severity: **P0 founder-proven OPPO search usability defect**
- Founder evidence: the focused Wholesale screenshot at
  `artifacts/quality/buy-flutter-r33-search-media-chat-oppo-20260730-25`
  shows the outline expanding while the old catalogue remains behind the
  keyboard. The field does not become a complete search task.
- Scope: native Shop, Wholesale and Medicine search. Orders keeps its
  order-specific search contract.
- Acceptance:
  1. Tapping the shared search owner opens a dedicated search/results surface
     below the branded header; the old promotions, category tools and
     catalogue cannot remain as misleading background content.
  2. The active field uses the available phone width, keeps Back, clear and
     scanner ownership unambiguous, and remains usable with the keyboard at
     320-pixel width and 140-percent text.
  3. Empty input explains the searchable scope without fake recent searches.
     Typed input shows the real matching product count and only products
     returned by the existing vertical-specific session query.
  4. Search results retain product media, seller/partner context, price,
     Saved, product detail and `+ / −` quantity actions.
  5. Back and close restore the exact vertical and scroll owner. Submitted
     search retains its query; explicit clear is the only action that clears
     it.
  6. Shop, Wholesale and Medicine remain independently filtered and no search
     result can cross a vertical contract.

### `BUY-FV2-095` — Provide truthful media coverage for every Buy catalogue product

- Status: **IMPLEMENTED, AUTOMATED AND CHECKSUM-MATCHED R33.4 OPPO VERIFIED
  2026-07-30 — FOUNDER REVIEW PENDING**
- Severity: **P0 founder-proven product-recognition defect**
- Founder evidence: R32 gives the first featured products a strong hero photo,
  while many dense-grid products still show a category symbol. The defect is
  visible across category, search, Saved, Shop, Wholesale and Medicine states.
- Scope: MoolSocial-owned native product/category media architecture and
  catalogue presentation. No marketplace photography may be copied.
- Acceptance:
  1. Every seeded Shop, Wholesale and Medicine product resolves to either an
     exact MoolSocial-owned product photo or a truthful MoolSocial-owned
     category photograph; the icon fallback remains only an asset-failure
     recovery path.
  2. Exact photos use `Product photo` semantics. Shared category media uses
     honest `Category photo` semantics and never claims to depict the exact
     SKU.
  3. Featured, dense-grid, search, Saved and product-detail owners use the
     same deterministic media resolver without changing product identifiers,
     price, partner, inventory, prescription or cart contracts.
  4. Media remains stable during decode, does not move purchase targets and
     fits compact/large Android and iOS-size viewports at 140-percent text.
  5. Generated-origin evidence, final asset checksums, dimensions, decode
     behavior and APK-size impact are recorded before founder review.
  6. An automated completeness test fails if any seeded production product
     lacks exact or truthful category media.

### `BUY-FV2-096` — Enhance Buy Chat with a compact motion-compatible support hierarchy

- Status: **IMPLEMENTED, AUTOMATED AND CHECKSUM-MATCHED R33.4 OPPO VERIFIED
  2026-07-30 — FOUNDER REVIEW PENDING**
- Severity: **P1 founder-directed Buy Chat design and interaction enhancement**
- Founder evidence: the current OPPO Chat screen is functional but visually
  flat, leaves large unused space and does not establish a clear progression
  from live order context to quick help, conversation and channel choice.
- Scope: native Buy/MoolSocial Assist presentation and existing session
  actions only.
- Acceptance:
  1. The first viewport clearly identifies live order context, current
     progress and the next useful support action without oversized empty
     regions.
  2. Quick intents, composer, in-app chat and in-app call have distinct,
     compact owners with 44-pixel targets and truthful availability copy.
  3. Every tap acknowledges immediately through shared Buy motion tokens and
     haptics; asynchronous wording cannot imply a backend operation that is
     not established.
  4. The screen uses no fake messages, agent identity, call connection,
     waiting state or support response. Existing notice/session behavior
     remains the only owner until a backend contract exists.
  5. Repeated Chat tap and Back return to the exact originating Buy state.
  6. The design fits 320-pixel width, representative Android/iOS sizes,
     140-percent text and reduced-motion mode without clipping or inaccessible
     actions.

### `BUY-FV2-097` — Preserve Account origin through Orders and child journeys

- Status: **IMPLEMENTED, AUTOMATED AND CHECKSUM-MATCHED R33.4 OPPO VERIFIED
  2026-07-30 — FOUNDER REVIEW PENDING**
- Severity: **P0 founder-proven navigation defect**
- Founder evidence: on the connected OPPO, Account/DC → Orders opens Orders
  without a usable return path to the Account hub.
- Scope: the existing native Buy session navigation state and explicit return
  affordances. No router or Account redesign.
- Acceptance:
  1. Account → Orders opens the established Orders surface and records Account
     as its immediate parent.
  2. Back from the Orders root returns to Account; deeper Orders states first
     return through their established order hierarchy and then to Account.
  3. Back from Account still returns to the exact Buy state from which Account
     was opened.
  4. Opening Orders from the bottom rail keeps its existing Shop-root return
     behavior and does not acquire an Account parent.
  5. Android system Back and the visible return owner follow the same state
     transition without duplicate pages or route loops.

### `BUY-FV2-098` — Add lazy horizontal continuation to every Buy product result surface

- Status: **IMPLEMENTED, AUTOMATED AND CHECKSUM-MATCHED R33.4 OPPO VERIFIED
  2026-07-30 — FOUNDER REVIEW PENDING**
- Severity: **P0 founder-directed catalogue scalability and discovery defect**
- Scope: Shop, Wholesale and Medicine catalogue, category, Saved and product
  search result surfaces. Existing vertical contracts remain independent.
- Acceptance:
  1. Product collections support left/right swipe with the next product cards
     continuing into view while the overall Buy page retains vertical
     discovery movement where it has additional sections.
  2. The product collection uses builder-based lazy child creation and does
     not eagerly construct product-card widgets for a large result set.
  3. Three compact columns remain visible on standard phone widths where
     fitment permits; 320-pixel and 140-percent-text layouts reduce safely
     without clipped price, media, Saved or quantity owners.
  4. Shop, Wholesale, Medicine, category, Saved and search filters continue to
     expose only the session products allowed by their existing contracts.
  5. Horizontal and vertical gestures do not capture the product, Saved,
     `+ / −`, Cart, category or system-Back tap owners.
  6. Semantics identify the collection as horizontally scrollable and expose
     an honest “swipe for more” discovery cue without claiming pagination that
     is not yet backed by an API.

### `BUY-FV2-099` — Make Account prescription Add complete visibly and reliably

- Status: **IMPLEMENTED, AUTOMATED AND CHECKSUM-MATCHED R33.4 OPPO VERIFIED
  2026-07-30 — FOUNDER REVIEW PENDING**
- Severity: **P0 founder-proven Account action defect**
- Scope: the existing local prescription-review contract and Account
  prescription sheet. No upload, pharmacist, backend or API behavior may be
  invented.
- Acceptance:
  1. The full “Add a new prescription” row and its Add owner are a keyed
     minimum-44-pixel tap target.
  2. One tap invokes the established `attachNewPrescription` session action
     exactly once, closes the sheet and exposes durable Account-level state
     showing that matched medicines are available.
  3. Existing saved-prescription choices and prescription quantity limits
     remain unchanged.
  4. No camera, file upload, pharmacist approval or asynchronous completion is
     claimed until such a production contract exists.
  5. A widget test reproduces Account → Prescriptions → Add and proves the
     session state and visible completion result.

### `BUY-FV2-100` — Wire Account Wholesale workspace to the real Wholesale catalogue

- Status: **IMPLEMENTED, AUTOMATED AND CHECKSUM-MATCHED R33.4 OPPO VERIFIED
  2026-07-30 — FOUNDER REVIEW PENDING**
- Severity: **P0 founder-proven Account action defect**
- Scope: the existing Account action and native Wholesale destination. Full
  Account/Profile redesign remains explicitly deferred.
- Acceptance:
  1. Account → Wholesale workspace opens the established Wholesale catalogue
     instead of displaying an informational notice.
  2. The existing verified-business restriction remains the only owner of
     Wholesale order eligibility.
  3. Back from the Wholesale root returns to Account, and Back from Account
     returns to the Buy state that originally opened Account.
  4. Product, category, search and Cart behavior inside Wholesale retain their
     existing vertical contract.
  5. No new business-profile field, status or backend behavior is introduced.

### `BUY-FV2-101` — Move product-add acknowledgement into the persistent Cart bar

- Status: **IMPLEMENTED, AUTOMATED AND CHECKSUM-MATCHED R33.4 OPPO VERIFIED
  2026-07-30 — FOUNDER REVIEW PENDING**
- Severity: **P0 founder-proven acknowledgement-placement defect**
- Scope: successful catalogue/cart quantity mutations and the existing
  aggregate Cart bar.
- Acceptance:
  1. A successful `+`, increase, decrease or removal updates a dedicated Cart
     acknowledgement state; it does not create the top transient add toast.
  2. When the aggregate Cart bar is visible, its long text owner briefly shows
     the affected product and resulting Cart state before returning to the
     normal item summary.
  3. Cart total, item count and “View cart” remain visible and tappable during
     acknowledgement, including at 320-pixel width and 140-percent text.
  4. Prescription limits, invalid products, save feedback, scanning feedback
     and other non-Cart notices retain their established notice/error owners.
  5. Screen disposal cancels both notice timers and no delayed callback acts on
     a disposed session owner.
  6. Session and widget tests prove that successful add feedback appears in
     the Cart bar and no `buy-live-notice` is created for that mutation.

### `BUY-FV2-102` — Scroll each horizontal product lane independently

- Status: **IMPLEMENTED, AUTOMATED AND CHECKSUM-MATCHED R33.4 OPPO VERIFIED
  2026-07-30 — FOUNDER REVIEW PENDING**
- Severity: **P0 founder-proven product-discovery interaction defect**
- Founder evidence: the connected-device review showed that one horizontal
  swipe moved both rows of the product grid together. The founder requires
  one lane to move at a time so the untouched lane remains a stable visual
  reference.
- Scope: Shop, Wholesale and Medicine catalogue, category, Saved and search
  product collections. No catalogue, price, inventory or backend contract
  change.
- Acceptance:
  1. The upper and lower product lanes have independent horizontal scroll
     positions; a gesture inside one lane cannot move the other lane.
  2. Both lanes retain builder-based lazy child creation and expose products
     in deterministic catalogue order without duplication or omission.
  3. Each lane has its own horizontal-scroll semantics and persistent
     destination/category/saved-state storage key.
  4. The containing page retains vertical discovery, and product, Saved,
     `+ / −`, Cart, category and Back tap owners remain unaffected.
  5. One-product results use one lane without reserving a blank second lane.
  6. Widget and screenshot evidence proves upper-only movement followed by
     independent lower-lane movement at a representative phone viewport.

### `BUY-FV2-103` — Close the expanded search owner before opening deeper Buy states

- Status: **IMPLEMENTED, AUTOMATED AND CHECKSUM-MATCHED R33.4 OPPO VERIFIED
  2026-07-30 — FOUNDER REVIEW PENDING**
- Severity: **P0 OPPO-proven navigation and state-ownership defect**
- Device evidence: on checksum-matched `1.0.0-r33.2`, DC opened from active
  Shop search changed the header to Account while leaving the search-result
  body mounted, so the Account actions were inaccessible.
- Scope: local native Flutter search-owner state only. No query, catalogue,
  Account, router or backend contract change.
- Acceptance:
  1. Opening Account, product detail, Chat/Assist or any other non-catalogue
     depth closes the expanded search owner before the destination surface
     paints.
  2. The submitted query remains in the session and is restored with the
     exact catalogue origin when the deeper state closes.
  3. Account controls and product detail can never be visually replaced by a
     stale search-results body under a changed header.
  4. Destination changes continue to close search as before; collapsed
     catalogue filtering and explicit query clear behavior are unchanged.
  5. Widget tests reproduce active search → Account and active search →
     product detail and prove the intended owner is mounted.

### `BUY-FV2-104` — Replace the boxed active search with one responsive search surface

- Status: **IMPLEMENTED, AUTOMATED AND CHECKSUM-MATCHED R33.4 OPPO VERIFIED
  2026-07-30 — FOUNDER REVIEW PENDING**
- Severity: **P0 founder-proven search usability and fitment defect**
- Founder evidence: the active Shop, Wholesale, Medicine and Orders search
  feels boxed, spends useful typing width on a Back arrow and expands more
  heavily than the task requires.
- Scope: the shared native Flutter Buy search owner only. Search results,
  vertical filtering, scanner, query retention and backend contracts remain
  unchanged.
- Acceptance:
  1. Active search is one soft, continuous surface and does not render a
     Back-arrow owner or a second nested field outline.
  2. The transition from rest to active search is compact and motion-aware,
     expanding by no more than four pixels in control height while respecting
     the device reduced-motion setting.
  3. Search input keeps at least 60 percent of the active surface width at
     representative Android and iOS-size viewports before a query is entered.
  4. A compact, explicitly labelled finish owner closes search without
     clearing the query; the clear owner appears only for non-empty input and
     clears without closing search.
  5. Every visible owner retains a minimum 44-pixel touch target, the scanner
     remains available at rest, and Android system Back continues to close
     active search first.
  6. The same owner and behavior apply to Shop, Wholesale, Medicine and
     Orders without changing vertical-specific filtering or navigation.

R33 completion evidence:

- Final source fingerprint:
  `7B293FB7D81F840BE42902A6C9F8221953D17FAA516D2656C7A11B2C5862145F`
  across the unchanged 33-file Buy source/test/asset manifest.
- Final device-review candidate:
  `BUY-R33-SEARCH-MEDIA-ACCOUNT-INDEPENDENT-LANES-RESPONSIVE-SEARCH-DEVICE`,
  version `1.0.0-r33.4` (`versionCode 2026073042`).
- Candidate and pulled installed OPPO APK SHA-256:
  `9DC65FC11EA5DD3CE086457AE85ED034D396F9E8953E2E2B7B36E019E2709A15`.
- Two unchanged-source Buy regressions each passed `104` tests with three
  opt-in screenshot generators skipped. Full Flutter analysis and the focused
  responsive-search tests passed.
- The final OPPO replay verified rest, active, clear, finish and retained-query
  search states in Shop, Wholesale, Medicine and Orders; Android Back keyboard
  precedence; active-search background/resume; active search to Account;
  clean Account to Orders entry; and direct Orders to Account toggle return.
- Shop and Wholesale upper/lower product lanes were swiped independently on
  the final OPPO candidate: movement in one lane left the neighboring lane's
  bounds unchanged. Medicine exposed two independent lane owners; the current
  unfiltered fixture contains one additional card in each lane, so it has no
  displacement to perform. Medicine upper/lower displacement remains captured
  in the earlier checksum-matched R33 lane replay using the same lane
  implementation and a multi-result search.
- The final post-resume device log contains no `FATAL EXCEPTION`, unhandled
  Flutter exception, `RenderFlex`, overflow or disposed-state callback
  finding.
- Protected Social tree
  `54851b4769c6a0087f586ce6c9325bbee1d7c790e06488eccae3a62ca953332e`,
  approved UI locks, brand integrity, founder-FINAL Buy reference,
  customer-copy, nine-state HTML copy and the 154-route interaction contract
  all passed.
- Durable evidence:
  `artifacts/quality/buy-flutter-r33-search-media-chat-oppo-20260730-25`.
- The earlier `1.0.0-r33.3` build is preserved as rejected diagnostic evidence
  because its device-review runtime flags were inconsistent. It is not the
  review candidate and is not an accepted baseline.

### `BUY-FV2-105` — Show truthful vertical-specific searches when search expands

- Status: **IMPLEMENTED, AUTOMATED AND CHECKSUM-MATCHED R34 OPPO VERIFIED
  2026-07-30 — FOUNDER REVIEW PENDING**
- Severity: **P0 founder-directed search discovery and effort defect**
- Founder direction: expanded search must immediately show useful searches so
  a customer can tap or type. Shop, Wholesale and Medicine must keep separate
  search buckets.
- Scope: the empty expanded native Flutter search/results state and a
  replaceable session suggestion boundary. No backend endpoint, popularity,
  personal history or business rule may be invented.
- Acceptance:
  1. Empty expanded Shop, Wholesale and Medicine search shows a compact
     destination-labelled set of tappable search suggestions while the field
     remains focused and typeable.
  2. Every suggestion is derived from a real product in the current
     destination catalogue/selection. The UI must not label local seed data as
     recent, popular, trending, recommended or personalized.
  3. Tapping a suggestion updates the same existing query owner as typing and
     immediately renders the real vertical-specific results. Clear returns to
     the suggestions without closing search.
  4. Shop suggestions can never query Wholesale or Medicine products;
     Wholesale suggestions can never query Shop or Medicine products; and
     Medicine suggestions can never query Shop or Wholesale products.
  5. The session exposes the suggestion list as a stable read-only boundary so
     a later established backend adapter can replace the seed source without
     changing the search presentation or query contract.
  6. Suggestion targets are at least 44 pixels, remain compact at 320-pixel
     width and 140-percent text, respect reduced motion and introduce no fake
     waiting or asynchronous state.
  7. Session/widget tests cover bucket separation, tap-to-query, typing, clear,
     destination switching and responsive fitment. Two same-source Buy
     regressions, protected gates and checksum-matched OPPO replay must pass.

Completion evidence:

- The session exposes a read-only `searchSuggestions` boundary. With no
  approved suggestion API, it returns at most four unique product titles from
  the active destination/category/filter result set and returns nothing for a
  non-empty query or Orders.
- Expanded search automatically shows only the compact destination bucket
  (`Shop suggestions`, `Wholesale suggestions` or `Medicine suggestions`).
  The founder-rejected instructional `Try...` / `Tap...` wording is absent.
- Suggestion taps call the same established `updateQuery` owner as typing.
  No popularity, history, trending, recommendation, personalization,
  asynchronous state or backend behavior was invented.
- Final source fingerprint:
  `8C8028A9ADB7665E7047D4B80B5B5CDFD09920A23402338837F3B9ADE6023AF2`
  across the unchanged 33-file manifest.
- Final candidate:
  `BUY-R34-VERTICAL-SEARCH-SUGGESTIONS-DEVICE`, version `1.0.0-r34`
  (`versionCode 2026073043`).
- Candidate and pulled installed OPPO APK SHA-256:
  `9010320F14F228DFC70B60431BE06D1F3E2BDD978AA80BA2B84213F510D926A2`.
- Two same-source Buy regressions each passed `106` tests with four opt-in
  additive capture generators skipped. Full analysis, focused tests and 12
  final Android/iOS-size suggestion captures passed.
- The OPPO replay found four Shop, four Wholesale and four Medicine
  suggestions. `Fresh tomatoes` opened the 500 g Shop offer in Shop and the
  10 kg trade offer in Wholesale; `Paracetamol 500 mg tablets` opened the
  Medicine offer; direct typing `pain` opened `Pain relief gel`.
- Clear restored the active destination suggestions, hot resume preserved the
  empty Shop suggestion state, and the final runtime audit contained no fatal
  Flutter exception, `E/flutter`, `RenderFlex`, overflow, disposed-state
  callback or app ANR.
- All protected Social, approved-lock, brand, founder-FINAL Buy reference,
  customer-copy, nine-state HTML and 154-route interaction gates passed.
- Durable handoff:
  `docs/quality/BUY-V2-R34-VERTICAL-SEARCH-SUGGESTIONS-HANDOFF-20260730.md`.
- Additive evidence remains under:
  `artifacts/quality/buy-flutter-r33-search-media-chat-oppo-20260730-25`.

### `BUY-FV2-106` — Replace the suggestion card with a flat autocomplete list

- Status: **FOUNDER APPROVED R35.1 BUY BASELINE — LOCAL COMMIT AUTHORIZED
  2026-07-31**
- Founder correction, 31 July 2026: the first checksum-matched R35 OPPO replay
  proved that 48-pixel suggestion rows and the remaining vertical list padding
  still looked too open. R35.1 must use the dense accessibility-safe
  44-pixel target, remove surplus top/bottom padding, retain the flat
  single-column reference structure and preserve all earlier R35 evidence.
- Severity: **P0 founder-rejected search suggestion hierarchy**
- Founder evidence: the R34 OPPO state still introduces a large decorated card
  with a destination heading, product count and explanatory scope text. The
  founder supplied a compact autocomplete-list reference and directed that
  the extra text and card treatment be removed.
- Scope: the empty expanded native Flutter suggestion presentation only.
  Existing vertical suggestion data, typing, query, results, clear, finish,
  scanner and navigation contracts remain unchanged.
- Acceptance:
  1. Suggestions begin directly below the active search band as a flat list;
     there is no suggestion heading, count, scope paragraph, instructional
     copy, gradient, enclosing card, oversized icon or decorative container.
  2. Every row shows only a truthful search icon and the catalogue-derived
     term. A clock/history icon is prohibited until a real search-history
     contract exists.
  3. Rows retain at least 44-pixel tap targets, subtle separators and compact
     spacing at 320-pixel width and 140-percent text.
  4. Shop, Wholesale and Medicine retain separate data buckets and tapping a
     row continues to use the established query/result owner.
  5. Direct typing, clear-to-list, finish, Android Back and background/resume
     behavior remain unchanged. Orders retains its order-search contract and
     receives no product suggestion list.
  6. Focused tests and additive Android/iOS-size captures prove the rejected
     heading/count/scope/card are absent. Two same-source Buy regressions,
     protected gates and checksum-matched OPPO replay must pass.
- Completion:
  - R35.1 renders only four flat rows directly below the active field. Each
    row contains one truthful search icon and catalogue-derived term.
  - The heading, count, scope/instruction copy, gradient, enclosing card,
    oversized illustration and false history affordance are absent.
  - Rows are exactly 44 Flutter logical pixels, verified as 88 physical pixels
    on the 2.0-density OPPO, with no top padding and only 8 pixels of trailing
    list padding.
  - Twelve additive captures passed at 320 x 568, 320 x 568 with 140-percent
    text, 390 x 844 iOS-size and 430 x 932 iOS-size for all three product
    verticals.
  - Two complete same-source Buy regressions passed `106/106`; four explicit
    capture generators were skipped in each normal run.
  - Protected Social, UI locks, brand, founder-FINAL Buy reference,
    user-facing copy, nine-state HTML copy and 154-route interaction gates
    passed.
  - The exact R35.1 candidate and pulled installed OPPO APK match SHA-256
    `10FC8C43626B7C2882A6340C6A3A4710C2092E4D45AB0A768CE7056F23BCB9C7`.
  - Device replay proved dense Shop, Wholesale and Medicine lists, separate
    500 g Shop and 10 kg Wholesale results for the same term, Medicine tap and
    direct typing, clear, and empty focused Shop hot resume. Runtime audit was
    clean.
- Durable handoff:
  `docs/quality/BUY-V2-R35-1-DENSE-FLAT-SEARCH-SUGGESTIONS-HANDOFF-20260731.md`.
- Additive R35.1 evidence:
  `artifacts/quality/buy-flutter-r35-1-dense-flat-search-suggestions-oppo-20260731-27`.
- Founder decision, 31 July 2026: the checksum-matched R35.1 OPPO candidate is
  approved as the protected native Buy baseline. A scoped local commit is
  authorized. Push, deployment, publication and production release remain
  separate decisions.

### `BUY-FV2-107` — Machine-protect the founder-approved native Buy baseline

- Status: **COMPLETE — PROTECTED BASELINE GATE VERIFIED 2026-07-31**
- Severity: **P0 regression-prevention boundary**
- Authority: founder approval of the checksum-matched R35.1 OPPO candidate and
  direction to keep the accepted production state safe.
- Scope:
  - record an additive machine-readable baseline for the exact approved Buy
    runtime tree and checksum-matched APK;
  - add a deterministic PowerShell gate using the repository's established
    portable SHA-256 and line-ending policy;
  - protect Buy runtime source, routing and approved media while allowing
    tests and documentation to advance independently;
  - add the gate to release policy without modifying application behavior.
- Acceptance:
  1. The gate enumerates exactly the approved Buy runtime roots and explicit
     files, rejects missing/added files and rejects any portable tree mismatch.
  2. The retained APK checksum is verified when the local audit artifact is
     present, while CI remains able to validate source without committing the
     approximately 200 MB APK.
  3. A clean baseline passes and an isolated copied-tree mutation fails with a
     truthful founder-approval error.
  4. The baseline records commit, candidate, installed checksum match,
     protected Social tree, verification status and future-work boundary.
  5. Existing Social, approved UI, brand, Buy reference, copy and interaction
     gates remain green. No Flutter runtime file changes.
- Completion:
  - Founder-approved baseline commit:
    `34045d33869e13ac17b03d59c2625f2d91a1fb92`.
  - Protected runtime inventory: `28` files.
  - Portable runtime tree:
    `f712b5b8ce10dd92b64babc4703379a24918fef5cef9417afe9c6679db79bc5d`.
  - The clean repository and an isolated clean copy passed.
  - An isolated copied-tree source mutation failed on tree checksum.
  - An isolated added runtime file failed on inventory count.
  - Full Flutter analysis passed.
  - Two complete Buy regressions passed `106/106`; four opt-in capture
    generators were skipped in each normal run.
  - Protected Buy, protected Social, approved UI locks, brand,
    founder-FINAL Buy reference, user-facing copy, nine-state HTML copy and
    154-route interaction gates passed.
  - The repository's main local quality command now invokes both protected
    Social and protected Buy baseline gates.
  - No application runtime, approved HTML or protected Social file changed.
- Durable handoff:
  `docs/quality/BUY-V2-R35-1-PROTECTED-BASELINE-GATE-HANDOFF-20260731.md`.
- Additive evidence:
  `artifacts/quality/buy-protected-baseline-r35-1-20260731-28`.

### `BUY-FV2-108` — Harden deterministic Buy state and mutation invariants

- Status: **COMPLETE — TEST-ONLY HARDENING VERIFIED 2026-07-31**
- Severity: **P1 regression, misuse and stale-identifier protection**
- Authority: founder direction to continue independently only where work can
  remain production-grade without subjective design or unapproved backend
  decisions.
- Scope:
  - add deterministic tests at the existing native `BuyV2Session` boundary;
  - exercise only established catalogue, cart, prescription, checkout,
    vertical-isolation and invalid-identifier behavior;
  - make no Flutter runtime, visual, approved-reference, Social, backend
    contract or business-rule change.
- Acceptance:
  1. Every non-prescription offer proves its established minimum-order add,
     increment, decrement and removal floor without negative quantity or total.
  2. Every prescription offer proves that add/increment remains blocked before
     a matched prescription and cannot silently enter the cart.
  3. Unknown product, order, address and payment identifiers, and invalid
     review/report inputs, fail closed without mutating unrelated valid state.
  4. Checkout projections, fulfilment-group lines and confirmed-order
     collections remain read-only; repeated confirmation cannot duplicate an
     order after the scoped cart has been consumed.
  5. A deterministic repeated vertical sequence proves Shop, Wholesale and
     Medicine category ownership remains separate while transient query and
     filter state cannot leak between destinations.
  6. Focused tests, full Flutter analysis, two same-source Buy regressions and
     all protected/reference/copy/interaction gates pass. Because this ticket
     changes no runtime bytes, the checksum-matched approved OPPO installation
     remains the exact device candidate and no rebuild is required.
- Completion:
  - Five focused invariant tests pass across every catalogue offer, including
    minimum-order quantity floors, prescription fail-closed behavior, invalid
    external identifiers, immutable checkout projections, single-use
    confirmation and repeated vertical traversal.
  - Full Flutter analysis passed.
  - Two identical-source Buy regressions each passed `111/111`; four explicit
    screenshot capture generators were skipped in each normal run.
  - Protected Buy, protected Social, approved UI locks, brand,
    founder-FINAL Buy reference, user-facing copy, nine-state HTML copy and
    154-route interaction gates passed.
  - Protected runtime remained exactly 28 files with tree
    `f712b5b8ce10dd92b64babc4703379a24918fef5cef9417afe9c6679db79bc5d`.
  - Read-only OPPO verification found the approved `1.0.0-r35.1`
    (`versionCode 2026073045`) installation and exact on-device APK SHA-256
    `10FC8C43626B7C2882A6340C6A3A4710C2092E4D45AB0A768CE7056F23BCB9C7`.
  - No application runtime, approved HTML, protected media or Social file
    changed; no APK rebuild or reinstall was necessary.
- Durable handoff:
  `docs/quality/BUY-V2-R35-1-STATE-INVARIANT-HARDENING-HANDOFF-20260731.md`.
- Additive evidence:
  `artifacts/quality/buy-r35-1-state-invariant-hardening-20260731-29`.

### `BUY-FV2-109` — Enforce the unapproved Buy backend-contract boundary

- Status: **COMPLETE — NONVISUAL RELEASE-GATE HARDENING VERIFIED 2026-07-31**
- Severity: **P1 production-integrity and contract-governance protection**
- Authority: founder direction not to invent backend behavior, business rules,
  database fields or API contracts that have not been established.
- Scope:
  - machine-check the protected native Buy V2 surface for direct transport,
    database, WebView, URL-launcher, endpoint, mock gateway and fabricated
    delayed-completion paths;
  - machine-check existing backend and contract trees for an unapproved Buy
    owner;
  - retain the one established first-party address-request support URL;
  - change no Flutter runtime, backend implementation, approved HTML, Social
    source or business rule.
- Acceptance:
  1. The current protected source passes and reports the scanned mobile,
     backend and contract inventory.
  2. A built-in adversarial self-test rejects direct HTTP/WebView imports,
     delayed completion, review gateway use, endpoint paths, external URLs and
     an invented backend service while accepting the established first-party
     address-request URL.
  3. The gate is part of the repository's main local quality command and the
     release policy explains how a future approved contract replaces this
     absence boundary.
  4. The gate does not classify the real camera scanner, notice lifetime,
     Flutter image placeholder builder or first-party address-request copy
     action as backend behavior.
  5. Full analysis, two same-source Buy regressions and all protected,
     reference, copy and interaction gates pass. No APK rebuild or reinstall
     is required because application runtime bytes remain unchanged.
- Completion:
  - The clean gate scanned eight native Buy V2 files, 72 existing backend
    files and one contract file. No invented Buy transport, production double,
    endpoint or backend owner was found.
  - The built-in adversarial self-test rejected six forbidden mobile paths and
    one invented backend owner, and accepted the established first-party
    address-request support link.
  - Gate SHA-256:
    `F223C823F12604B46F4EB29261D401F5522CA5EE4E166EFB1CDAAD48331251DB`.
  - The gate is wired into `scripts/check.ps1`; release policy now requires it
    until an approved contract package replaces the absence boundary.
  - Full Flutter analysis passed. Two same-source Buy regressions each passed
    `111/111`; four explicit capture generators were skipped in each normal
    run.
  - Protected Buy, protected Social, approved UI locks, brand,
    founder-FINAL Buy reference, user-facing copy, nine-state HTML copy and
    154-route interaction gates passed.
  - Read-only OPPO verification again matched approved version
    `1.0.0-r35.1` (`versionCode 2026073045`) and on-device APK SHA-256
    `10FC8C43626B7C2882A6340C6A3A4710C2092E4D45AB0A768CE7056F23BCB9C7`.
  - No mobile/backend runtime, approved HTML, protected media or Social file
    changed.
- Durable handoff:
  `docs/quality/BUY-V2-R35-1-BACKEND-CONTRACT-BOUNDARY-HANDOFF-20260731.md`.
- Additive evidence:
  `artifacts/quality/buy-r35-1-backend-contract-boundary-20260731-30`.

### `BUY-FV2-110` — Enforce the Buy V2 data-egress security boundary

- Status: **COMPLETE — NONVISUAL SECURITY HARDENING VERIFIED 2026-07-31**
- Severity: **P1 customer-data and credential exposure protection**
- Authority: founder direction to continue security/observability work without
  inventing backend behavior, fields or contracts.
- Scope:
  - machine-check the protected native Buy V2 surface for direct logging,
    analytics, crash-report, arbitrary clipboard/system-share, local-storage
    and embedded-credential sinks;
  - retain only the established first-party address-request clipboard action;
  - record—not conceal—the separate hard-coded review-identity fixture risk
    that cannot be removed without replacing the approved runtime;
  - change no Flutter runtime, backend, HTML, Social or business rule.
- Acceptance:
  1. The clean gate reports its exact protected V2 inventory and permits only
     the established first-party address-request clipboard action.
  2. Built-in adversarial tests reject diagnostic logging, analytics,
     unapproved storage, system sharing, arbitrary clipboard read/write and
     credential-like material while accepting approved clipboard and ordinary
     presentation cases.
  3. The gate is wired into the main quality command and release policy.
  4. The handoff explicitly records that the current protected session still
     contains hard-coded review recipient/contact/address fixture data. The
     gate prevents egress but does not misrepresent that fixture as a
     production identity source.
  5. Full analysis, two same-source Buy regressions and all protected,
     backend-boundary, reference, copy and interaction gates pass. Runtime is
     unchanged, so no APK rebuild or reinstall is required.
- Completion:
  - The clean gate scanned eight native Buy V2 files. It found no direct
    logging, analytics, crash-report detail, arbitrary system share,
    unapproved local store or embedded credential sink.
  - Seven adversarial egress cases were rejected; the established first-party
    address-request clipboard action and ordinary presentation were accepted.
  - Gate SHA-256:
    `BE184CC9E49FA87587628501D2AF2EA86375A73A95A59B3D1093DED76C016F0D`.
  - The gate is wired into `scripts/check.ps1` and item 29 of the release
    policy.
  - Full Flutter analysis passed. Two same-source Buy regressions each passed
    `111/111`; four explicit capture generators were skipped in each normal
    run.
  - Protected Buy, protected Social, backend-contract boundary, approved UI
    locks, brand, founder-FINAL Buy reference, user-facing copy, nine-state
    HTML copy and 154-route interaction gates passed.
  - The hard-coded review identity/contact/address fixture remains recorded as
    a release risk. It was not changed, allowlisted as a production identity
    source or copied into evidence.
  - Read-only OPPO verification matched approved `1.0.0-r35.1`
    (`versionCode 2026073045`) and on-device APK SHA-256
    `10FC8C43626B7C2882A6340C6A3A4710C2092E4D45AB0A768CE7056F23BCB9C7`.
  - No Flutter/backend runtime, HTML, protected media or Social source
    changed.
- Durable handoff:
  `docs/quality/BUY-V2-R35-1-DATA-EGRESS-BOUNDARY-HANDOFF-20260731.md`.
- Additive evidence:
  `artifacts/quality/buy-r35-1-data-egress-boundary-20260731-31`.

### `BUY-FV2-111` — Add conservative Buy in-process performance budgets

- Status: **COMPLETE — TEST-ONLY PERFORMANCE HARDENING VERIFIED 2026-07-31**
- Severity: **P1 deterministic performance-regression protection**
- Authority: founder priority for Buy performance checks that remain useful
  across later UI changes without inventing backend scale behavior.
- Scope:
  - measure the established native session/catalogue seam only;
  - cover repeated vertical search/filter projection, a full current-seed
    mixed cart and checkout grouping, and repeated vertical state traversal;
  - use conservative deterministic budgets suitable for normal CI variance;
  - change no Flutter runtime, UI, backend, HTML, Social or business rule.
- Acceptance:
  1. The current approved catalogue search/filter boundary completes a
     deterministic Shop/Wholesale/Medicine workload under a conservative
     budget and never returns a cross-vertical offer.
  2. Adding every unrestricted current-seed offer and repeatedly projecting
     checkout lines/groups stays under budget while preserving exact item and
     total arithmetic.
  3. Thousands of destination/query/filter transitions stay under budget and
     preserve independently owned category state.
  4. Test output records measured elapsed time; budgets are high enough to
     catch catastrophic regressions without pretending to benchmark release
     hardware.
  5. Handoff explicitly states that this does not prove million-product scale,
     ranking, pagination, cache or network latency. Those require approved
     backend contracts and server-side performance tests.
  6. Focused tests, full analysis, two same-source Buy regressions and every
     protected/security/reference/copy/interaction gate pass. Runtime remains
     unchanged, so no APK rebuild or reinstall is required.
- Completion:
  - Three deterministic performance tests cover 1,200 search/filter
    projections, a 172-offer mixed cart with 500 checkout projections, and
    6,000 vertical transitions.
  - Worst observed elapsed times across focused and full regression runs were
    174 ms, 286 ms and 19 ms respectively, against independent conservative
    8,000 ms guards.
  - Performance-test SHA-256:
    `A7F2E772BA96E1AC6BF3233887F8DC4410C4E5D2006444A4F0265655A4B07E62`.
  - Full Flutter analysis passed. Two same-source Buy regressions each passed
    `114/114`; four explicit capture generators were skipped in each normal
    run.
  - Protected Buy, protected Social, backend-contract, data-egress, approved
    UI locks, brand, founder-FINAL Buy reference, user-facing copy, nine-state
    HTML copy and 154-route interaction gates passed.
  - Read-only OPPO verification matched approved `1.0.0-r35.1`
    (`versionCode 2026073045`) and on-device APK SHA-256
    `10FC8C43626B7C2882A6340C6A3A4710C2092E4D45AB0A768CE7056F23BCB9C7`.
  - No runtime, HTML, protected media or Social source changed.
- Durable handoff:
  `docs/quality/BUY-V2-R35-1-PERFORMANCE-BUDGETS-HANDOFF-20260731.md`.
- Additive evidence:
  `artifacts/quality/buy-r35-1-performance-budgets-20260731-32`.

### `BUY-FV2-112` — Close deterministic Buy session coverage gaps

- Status: **COMPLETE — TEST-ONLY SESSION HARDENING VERIFIED 2026-07-31**
- Severity: **P1 commerce-state regression protection**
- Authority: founder direction to continue autonomous production hardening
  without subjective UI changes, backend invention or changes to the approved
  native runtime.
- Scope:
  - add focused tests for established Shop, Wholesale, Medicine and Orders
    session behavior that the R35.1 coverage audit proved was not executed;
  - cover vertical cart arithmetic and clearing, empty-state routing,
    account-entry behavior, wholesale and prescription fail-closed guards,
    navigation depth, recovery routing and explicit order-product projection;
  - use only synthetic test fixtures and change no Flutter runtime, UI,
    backend, HTML, Social or business rule;
  - exclude camera/plugin paths, presentation branches and silent
    selected-order/address fallbacks because those require device coverage or
    product judgment rather than test-only contract hardening.
- Acceptance:
  1. Orders remain category-neutral and cannot mutate a saved commerce
     category.
  2. Scoped line, item and total projections remain exact for Shop,
     Wholesale and Medicine, and clearing any established scope returns to
     its own safe catalogue.
  3. Empty cart and checkout entry points, direct account-child actions and
     repeated account taps retain their established deterministic routes.
  4. An unverified wholesale session and prescription quantities fail closed
     without unauthorized cart mutation.
  5. Cart, checkout, confirmation, order-items and recovery back/retry paths
     retain the established depth and explicit confirmed-order product IDs.
  6. The before/after report records protected Buy line coverage without
     overstating uncovered camera/plugin or visual behavior.
  7. Focused tests, full analysis, two same-source Buy regressions and every
     protected/security/reference/copy/interaction gate pass. Runtime remains
     unchanged, so no APK rebuild or reinstall is required.
- Additive evidence:
  `artifacts/quality/buy-r35-1-coverage-gap-audit-20260731-33`.
- Completion:
  - Eight deterministic tests now protect category-neutral Orders behavior,
    vertical cart arithmetic and clearing, empty-state normalization, direct
    and repeated account actions, wholesale and prescription limits,
    Wholesale/Medicine reorder scope, navigation/recovery depth, explicit
    confirmed-order product IDs, final removal and synthetic-address state.
  - The focused suite passed `8/8`. Protected Buy V2 line coverage increased
    from `3595/4290` (`83.8%`) to `3665/4290` (`85.4%`); session coverage
    increased from `594/673` (`88.3%`) to `664/673` (`98.7%`) without a
    production-line change.
  - The nine remaining uncovered session lines are short-circuit operands,
    unreachable Orders enum arms or the two silent selected-order/address
    fallback policies intentionally excluded from this test-only contract.
  - Full Flutter analysis passed. Two same-source Buy regressions each passed
    `122/122`; four opt-in capture generators were skipped in each normal run.
  - Protected Buy, protected Social, backend-contract, data-egress, approved
    UI locks, brand, founder-FINAL Buy reference, user-facing copy,
    nine-state HTML copy and 154-route interaction gates passed.
  - Read-only OPPO verification matched approved `1.0.0-r35.1`
    (`versionCode 2026073045`) and on-device APK SHA-256
    `10FC8C43626B7C2882A6340C6A3A4710C2092E4D45AB0A768CE7056F23BCB9C7`.
  - No runtime, backend, HTML, protected media or Social source changed, so
    no APK rebuild or reinstall was required.
- Durable handoff:
  `docs/quality/BUY-V2-R35-1-SESSION-COVERAGE-HANDOFF-20260731.md`.

### `BUY-FV2-113` — Add deterministic mixed-operation state-machine coverage

- Status: **COMPLETE — TEST-ONLY INTERLEAVING HARDENING VERIFIED 2026-07-31**
- Severity: **P1 commerce-state corruption protection**
- Authority: founder direction to continue autonomous Buy regression
  hardening without subjective UI work or invented backend behavior.
- Scope:
  - execute a fixed, reproducible sequence of mixed Buy session actions across
    Shop, Wholesale, Medicine and all cart scopes;
  - interleave add/increase/decrease/remove, destination/scope changes,
    catalogue/cart/account/recovery navigation, checkout and confirmation;
  - prove exact quantity, price, destination, scoped-cart, checkout and
    fulfilment-group invariants after every action;
  - change no Flutter runtime, UI, backend, HTML, Social or business rule.
- Acceptance:
  1. At least 2,000 deterministic mixed actions execute every action family,
     every commerce destination and every cart scope.
  2. After every action, total item count and value equal the exact sum of all
     product quantities and prices, and no line falls below its minimum order.
  3. Cart and checkout projections expose only their selected scope and their
     destination sets, counts, totals and fulfilment groups remain exact.
  4. Confirming a scoped checkout removes only those exact product IDs,
     preserves every out-of-scope line and records exact confirmed totals.
  5. The sequence has no wall-clock assertion and uses no randomness,
     network, plugin, device, production identity or personal-data fixture.
  6. Focused tests, full analysis, two same-source Buy regressions and every
     protected/security/reference/copy/interaction gate pass. Runtime remains
     unchanged, so no APK rebuild or reinstall is required.
- Additive evidence:
  `artifacts/quality/buy-r35-1-state-machine-hardening-20260731-34`.
- Completion:
  - One fixed 2,400-step state-machine test exercises all 12 action families,
    all three commerce destinations and all four cart scopes.
  - Every step recomputes and verifies global/scoped/checkout quantities,
    values, destination ownership and fulfilment grouping from the 172
    unrestricted offer records; periodic scoped confirmations also prove
    exact removal and confirmed-order projection.
  - The focused test passed. Its first attempt exposed a low-bit LCG action
    selection flaw; explicit round-robin action scheduling fixed the test
    design, and the failed attempt remains preserved.
  - Full Flutter analysis passed. Two same-source Buy regressions each passed
    `123/123`; four opt-in capture generators were skipped in each normal run.
  - Protected Buy, protected Social, backend-contract, data-egress, approved
    UI locks, brand, founder-FINAL Buy reference, user-facing copy,
    nine-state HTML copy and 154-route interaction gates passed.
  - Read-only OPPO verification matched approved `1.0.0-r35.1`
    (`versionCode 2026073045`) and on-device APK SHA-256
    `10FC8C43626B7C2882A6340C6A3A4710C2092E4D45AB0A768CE7056F23BCB9C7`.
  - No runtime, backend, HTML, protected media or Social source changed, so
    no APK rebuild or reinstall was required.
- Durable handoff:
  `docs/quality/BUY-V2-R35-1-STATE-MACHINE-HANDOFF-20260731.md`.

### `BUY-FV2-114` — Protect Buy listener liveness and no-op semantics

- Status: **COMPLETE — TEST-ONLY ACTION-LIVENESS HARDENING VERIFIED 2026-07-31**
- Severity: **P1 silent-action regression protection**
- Authority: founder requirement that every meaningful action acknowledge the
  customer and autonomous authorization for nonvisual Buy test hardening.
- Scope:
  - prove that established state-changing, navigation and fail-closed session
    actions notify their native Flutter listeners;
  - prove that true missing-target/no-state-change operations remain silent;
  - validate notification liveness only, not exact callback counts, timing,
    animation, visual design or unapproved backend progress;
  - change no Flutter runtime, UI, backend, HTML, Social or business rule.
- Acceptance:
  1. Critical catalogue, cart, checkout, Orders, Account, assistance, recovery,
     address, payment, review, report, prescription and notice actions each
     emit at least one listener notification when they change customer-visible
     state.
  2. Invalid customer inputs that produce an established notice also notify,
     so the UI cannot silently retain stale state.
  3. Missing-line removal/decrease and empty acknowledgement clearing remain
     silent because they change no state and create no customer message.
  4. Tests avoid exact notification counts so compound actions may retain
     their established internal composition.
  5. Focused tests, full analysis, two same-source Buy regressions and every
     protected/security/reference/copy/interaction gate pass. Runtime remains
     unchanged, so no APK rebuild or reinstall is required.
- Additive evidence:
  `artifacts/quality/buy-r35-1-listener-liveness-hardening-20260731-35`.
- Completion:
  - Three focused tests cover 60 customer-visible/state-changing or
    fail-closed action cases and five deliberate true no-ops.
  - Every catalogue, cart, checkout, Orders, Account, assistance, recovery,
    address, payment, review, report, prescription and notice case emitted at
    least one listener notification when it changed visible state or produced
    an established customer notice.
  - Missing-line decrease/removal, inactive Account return and empty
    notice/acknowledgement clearing emitted no synthetic progress.
  - Full Flutter analysis passed. Two same-source Buy regressions each passed
    `126/126`; four opt-in capture generators were skipped in each normal run.
  - Protected Buy, protected Social, backend-contract, data-egress, approved
    UI locks, brand, founder-FINAL Buy reference, user-facing copy,
    nine-state HTML copy and 154-route interaction gates passed.
  - Read-only OPPO verification matched approved `1.0.0-r35.1`
    (`versionCode 2026073045`) and on-device APK SHA-256
    `10FC8C43626B7C2882A6340C6A3A4710C2092E4D45AB0A768CE7056F23BCB9C7`.
  - No runtime, backend, HTML, protected media or Social source changed, so
    no APK rebuild or reinstall was required.
- Durable handoff:
  `docs/quality/BUY-V2-R35-1-LISTENER-LIVENESS-HANDOFF-20260731.md`.

### `BUY-FV2-115` — Protect order-history partition and live-progress integrity

- Status: **COMPLETE — TEST-ONLY ORDER-INTEGRITY HARDENING VERIFIED 2026-07-31**
- Severity: **P1 order traceability and progress protection**
- Authority: founder requirement that every order and tracking action show
  truthful progress, plus autonomous authorization for nonvisual Buy tests.
- Scope:
  - validate completeness, identity, destination and progress bounds for every
    established order record;
  - prove Active and Delivered are a lossless, disjoint partition of order
    history and exact order-ID search remains tab-scoped;
  - confirm a mixed Shop/Wholesale/Medicine checkout creates traceable,
    non-complete live orders with exact vertical product IDs and totals;
  - change no Flutter runtime, UI, backend, HTML, Social or business rule.
- Acceptance:
  1. Every established order has a unique non-empty ID, valid commerce
     destination, positive total, complete partner/delivery facts and progress
     in `(0, 1]`.
  2. Delivered orders are exactly `1.0`; active orders remain below `1.0`.
  3. Active and Delivered tab IDs are disjoint and their union is the complete
     order history; exact ID search returns only that order in its owning tab.
  4. Mixed confirmation creates exact Shop/Wholesale/Medicine order IDs,
     product IDs, totals, progress and active-tab ownership.
  5. Focused tests, full analysis, two same-source Buy regressions and every
     protected/security/reference/copy/interaction gate pass. Runtime remains
     unchanged, so no APK rebuild or reinstall is required.
- Additive evidence:
  `artifacts/quality/buy-r35-1-order-progress-hardening-20260731-36`.
- Completion:
  - Three focused tests validate every established order record, prove Active
    and Delivered form a disjoint lossless history partition, and confirm
    exact mixed-vertical live-order projection.
  - All current and generated orders have valid commerce destinations,
    complete delivery/partner facts and progress in `(0, 1]`; delivered
    records are exactly `1.0` and active records remain below completion.
  - Exact ID search stayed inside its owning tab. Mixed confirmation created
    traceable Shop, Wholesale and Medicine orders with exact prefixes,
    product IDs, totals, progress and active ownership.
  - Full Flutter analysis passed. Two same-source Buy regressions each passed
    `129/129`; four opt-in capture generators were skipped in each normal run.
  - Protected Buy, protected Social, backend-contract, data-egress, approved
    UI locks, brand, founder-FINAL Buy reference, user-facing copy,
    nine-state HTML copy and 154-route interaction gates passed.
  - Read-only OPPO verification matched approved `1.0.0-r35.1`
    (`versionCode 2026073045`) and on-device APK SHA-256
    `10FC8C43626B7C2882A6340C6A3A4710C2092E4D45AB0A768CE7056F23BCB9C7`.
  - No runtime, backend, HTML, protected media or Social source changed, so
    no APK rebuild or reinstall was required.
- Durable handoff:
  `docs/quality/BUY-V2-R35-1-ORDER-PROGRESS-HANDOFF-20260731.md`.

### `BUY-FV2-116` — Exhaust independent vertical discovery contracts

- Status: **COMPLETE — TEST-ONLY DISCOVERY HARDENING VERIFIED 2026-07-31**
- Severity: **P1 search and category isolation protection**
- Authority: founder direction to keep Shop, Wholesale and Medicine
  independently configurable, plus autonomous authorization for nonvisual Buy
  regression hardening.
- Scope:
  - exhaustively search every established offer ID in Shop, Wholesale and
    Medicine and prove it resolves only inside its owning vertical;
  - validate every category projection, including empty categories and the
    prescription aggregate, against exact ordered catalogue membership;
  - prove category suggestions remain bounded, unique, truthful and confined
    to the active destination/category projection;
  - change no Flutter runtime, UI, backend, HTML, Social or business rule.
- Acceptance:
  1. All 176 offer IDs are discoverable in their owning vertical and return
     zero results in each other vertical; additional same-vertical substring
     matches remain allowed by the established search contract.
  2. All 84 category selections across Shop, Wholesale and Medicine return
     their exact ordered product projection; the established 18-item “All”
     presentation bound remains explicit.
  3. Every suggestion list contains at most four unique non-empty titles from
     the active projection, and selecting a suggestion cannot escape its
     active destination or category.
  4. Orders exposes no product suggestions.
  5. Focused tests, full analysis, two same-source Buy regressions and every
     protected/security/reference/copy/interaction gate pass. Runtime remains
     unchanged, so no APK rebuild or reinstall is required.
- Additive evidence:
  `artifacts/quality/buy-r35-1-discovery-contract-hardening-20260731-37`.
- Completion:
  - Three focused tests execute all 176 established offer IDs against all
    three commerce verticals, all 84 category selections and every resulting
    category-suggestion state.
  - Every offer ID remained discoverable in its owning vertical and returned
    no result in either other vertical. Same-vertical substring matches remain
    valid; the first overly strict singleton assertion exposed this search
    nuance and its failed output remains preserved.
  - Every category returned its exact ordered catalogue projection, including
    empty categories, the Medicine prescription aggregate and the explicit
    18-item “All” presentation bound.
  - Suggestions remained unique, non-empty, limited to four, sourced from the
    active projection and unable to cross destination or category ownership.
    Orders exposed none.
  - Full Flutter analysis passed. Two same-source Buy regressions each passed
    `132/132`; four opt-in capture generators were skipped in each normal run.
  - Protected Buy, protected Social, backend-contract, data-egress, approved
    UI locks, brand, founder-FINAL Buy reference, user-facing copy,
    nine-state HTML copy and 154-route interaction gates passed.
  - Read-only OPPO verification matched approved `1.0.0-r35.1`
    (`versionCode 2026073045`) and on-device APK SHA-256
    `10FC8C43626B7C2882A6340C6A3A4710C2092E4D45AB0A768CE7056F23BCB9C7`.
  - No runtime, backend, HTML, protected media or Social source changed, so
    no APK rebuild or reinstall was required.
- Durable handoff:
  `docs/quality/BUY-V2-R35-1-DISCOVERY-CONTRACT-HANDOFF-20260731.md`.

### `BUY-FV2-117` — Fail closed on stale Buy address and order ownership

- Status: **R36 CHECKSUM-MATCHED OPPO VERIFIED — FOUNDER COMBINED REVIEW
  PENDING 2026-07-31**
- Severity: **P0 checkout-address and order-identity integrity**
- Authority: founder direction on 31 July 2026 to execute Ticket 117 together
  with Tickets 076 through 085 against the protected R35.1 baseline.
- Existing risk:
  - `BuyV2Session.addresses` and `BuyV2Session.orders` expose live mutable
    lists; and
  - selected-address and selected-order lookup silently substitutes the first
    record when the selected identifier is missing or stale.
- Scope:
  - native Buy V2 session ownership, read-only projections and fail-closed
    customer recovery only;
  - no backend, identity, persistence, API, database or business-rule
    invention;
  - preserve valid Shop, Wholesale, Medicine, Cart, Checkout, Orders,
    tracking, Account and reorder behavior.
- Acceptance:
  1. Public address and order collections are unmodifiable projections; only
     named session operations may change the owned records.
  2. Missing or stale selected identifiers never silently select a different
     address or order.
  3. Checkout and confirmation stop before order creation when no valid saved
     address is selected, retain the cart and expose concise address recovery.
  4. Tracking, order items, Back and Account restoration recover to Orders
     with `This order could not be found.` when their selected order is stale.
  5. Choosing or adding a valid address and opening a valid order retain the
     established result, listener acknowledgement and navigation behavior.
  6. Focused tests cover attempted public mutation, stale/missing address and
     order recovery, no silent substitution and unchanged valid journeys.
  7. Full analysis, two same-source Buy regressions, protected reference,
     copy, brand, Social, security and connected-OPPO gates pass before the
     combined R36 candidate is offered for founder review.

### `BUY-FV2-118` — Make OPPO review-build provenance fail closed

- Status: **COMPLETE — R36 GUARDED BUILD, RUNTIME MARKER AND INSTALLED
  CHECKSUM VERIFIED 2026-07-31**
- Severity: **P0 candidate-identity and device-replay integrity**
- Founder finding: review builds repeatedly lose time to configuration mistakes
  that are visible only after installation.
- Proven R36 reproduction:
  - a direct `flutter build apk` produced the correct source and version but
    omitted `MOOLSOCIAL_DEVICE_REVIEW` and `MOOLSOCIAL_CANDIDATE_ID`;
  - the checksum-matched OPPO installation therefore opened real sign-in and
    logged candidate ID `unidentified`; and
  - version name, version code and APK checksum alone could not prove that the
    intended runtime mode was present.
- Scope:
  - guarded local device-review build entry point;
  - explicit candidate ID, device-review and emulator-isolation defines;
  - clean deterministic final build;
  - installed runtime-marker verification;
  - additive rejected-build evidence.
- Acceptance:
  1. The supported Buy device-review build command requires a non-empty
     candidate ID, version, version code, source fingerprint and additive
     artifact directory.
  2. The command always supplies `MOOLSOCIAL_DEVICE_REVIEW=true`,
     `MOOLSOCIAL_USE_EMULATORS=true` and the exact
     `MOOLSOCIAL_CANDIDATE_ID`.
  3. Final candidate creation uses a clean generated build and refuses to
     overwrite an existing evidence APK or manifest.
  4. Post-install verification fails unless logcat exposes the exact candidate
     marker and a ready authenticated review state.
  5. Every rejected APK, checksum, screenshot and diagnosis remains preserved
     and is explicitly ineligible for founder acceptance.
