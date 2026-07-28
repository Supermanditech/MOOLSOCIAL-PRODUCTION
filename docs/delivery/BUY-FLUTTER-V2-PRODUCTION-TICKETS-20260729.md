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
- `BUY-FV2-022`: the exact final committed release candidate, two complete
  regression runs and founder Flutter acceptance remain open.
- the repository-wide Flutter suite has unrelated/stale legacy visual-golden
  debt. Buy-owned functional, responsive, router and legacy behavior suites
  are maintained separately; the global debt must not be hidden by updating
  unrelated goldens during the Buy task.
- live commerce catalogue, payment, fulfilment, pharmacy, address-request and
  production backend activation remain separate integration/release gates.
