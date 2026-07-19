# QA-017 — Manufacturer sales, procurement, growth and control

Date: 19 July 2026

## Scope

- Approved HTML behavior source: screens 107–115
- Manufacturer home, priority actions, orders and supply availability
- Business Book, catalogue, stock, sales-order review and fulfilment
- Input procurement, protected purchase order, receipt, dispatch and delivery
- Buyer demand, funded outcome campaigns, claims, team, settings and support
- MoolSocial-operated manufacturer services with plan, price, proof and
  cancellation review before a request
- Invalid, empty, duplicate, cancelled, loading, retry, offline,
  permission-denied and gateway-failure outcomes

## Screen-by-screen tap and nested-tap coverage

| Approved screen | Production intent path | Covered controls and nested outcomes |
|---:|---|---|
| 107 | Operate the manufacturer workspace and act on urgent work | Alerts; Live/Paused supply; exact supply failure and retry; search; clear; voice; scan sheet and close; verified-business settings; Business Book; priority order; add products; update stock; dispatch; GST invoice; Business Services; demand pool; input matches; Orders; Need action, Retailers, Hotels, Restaurants and Distributors filters; unmatched-order empty recovery; every order; export |
| 108 | Read business position and open the underlying records | Back; period sheet; This week; operating-position visibility; attention sheet; Sales, Purchases, Receivables and Payables records; Cash, Expenses, Notes, Reconcile, Documents and Reports tools; GST and filing service boundary |
| 109 | Publish or update one valid buyer-visible product | Back; Stock and Product Master modes; search and clear; filters; Product Master, template, scan and not-listed tools; every product; quantity; buyer price; MOQ; terms; invalid MOQ; input mapping; gateway failure; exact publish retry; duplicate publish; unmatched-product empty recovery |
| 110 | Make one explicit sales-order decision and move it to fulfilment | Back; buyer chat; Full, Partial and Cannot fulfil decisions; invalid partial quantity; required reason; production date; note; Full, Partial and Cannot fulfil validations; failed confirm; exact retry; duplicate confirm; production; packed; documents sheet; transport; dispatch route |
| 111 | Compare inputs and complete one purchase order through receipt | Back; Matched inputs, Raw material, Packaging and Machinery filters; every supplier term sheet; add every MOQ; Matched, Cart and Orders tabs; remove cart item; empty cart; failed PO; exact retry; duplicate PO; receipt; duplicate receipt |
| 112 | Dispatch a confirmed order with required identity and documents | Back; Ready, In transit and Delivered tabs; GST invoice, LR and e-way bill document controls; MoolSocial transport and own fleet; invalid vehicle; failed dispatch; exact retry; duplicate dispatch; tracking sheet; mark delivered; buyer receipt; duplicate receipt |
| 113 | Find buyer demand and publish a capped, outcome-based campaign | Back; Buyers, Demand, Campaigns and Analytics tabs; buyer details; demand details; campaign sheet; invalid target; target and maximum funding; review; failed publish; exact retry; duplicate publish; attribution rule |
| 114 | Resolve claims and control team, settings and support | Back; Claims, Team, Settings and Support tabs; every claim; evidence toggle; invalid claim state; failed resolution; exact retry; duplicate resolution; Add team; cancel invite; invalid mobile; role; failed invite; exact retry; duplicate invite; business, model, capacity, fleet, security and alerts settings; failed save; exact retry; duplicate save; support routes |
| 115 | Compare a manufacturer service and submit one reviewed request | Back; Services, Active and Requests tabs; every service; plan, coverage, base, success charge, term, proof and cancellation; request without accepting terms; failed request; exact retry; duplicate request; active service and current-request records |

## Locked operating rules

- Pausing supply never hides or cancels existing confirmed orders.
- A product is buyer visible only after valid stock, price, MOQ, terms and
  manufacturing-input mapping are confirmed.
- A sales order is never silently reduced. Full, partial and cannot-fulfil
  decisions are explicit, and cannot-fulfil requires a buyer-readable reason.
- Dispatch cannot complete without GST invoice, LR, e-way bill and the
  selected transport identity.
- Purchase orders use verified input MOQs and preserve the cart through
  failure. Receipt records grade, quantity and condition once.
- Campaign funding is a hard maximum. Only approved activations or paid,
  non-refunded attributed sales count; views are not charged as outcomes.
- Claims retain selected evidence and resolution through failure and retry.
- Team invitations and settings saves require permitted access and commit once.
- A Business Service request cannot be submitted until coverage, charges,
  proof and cancellation have been reviewed and accepted.
- Duplicate commands never create a second product, confirmation, PO, receipt,
  dispatch, campaign, resolution, invitation, settings version or service
  request.

## Defects discovered, root cause, fix and exact replay

| Ticket | Defect and root cause | Fix | Exact original replay |
|---|---|---|---|
| MF-001 | The app-bar supply action inherited the global full-width filled-button minimum, producing an infinite-width layout failure inside the toolbar | Replaced it with a compact, bounded, semantic Live/Paused capsule | Screen 107 at 412 px → supply control: toolbar renders, failure preserves Live, exact retry shows Paused |
| MF-002 | Fixed-width tab groups could not contain long procurement, dispatch, service and transport labels | Rebuilt these groups as horizontally scrollable 44 px pill rails | Screens 111, 112 and 115 → traverse every tab/transport option: no clipping or overflow and every option remains tappable |
| MF-003 | A section title and right-side detail competed for intrinsic width at compact size | Constrained both regions, gave the title priority and added controlled wrapping/ellipsis | Screens 107–115 at 412 × 915: every section heading and supporting detail renders without overflow |
| MF-004 | Long invoice terms were unbounded on the right side of a two-column row | Made both label and value flexible with bounded lines and ellipsis | Screen 110 → invoice and payment terms: all rows remain inside the card |
| MF-005 | The original supply icon communicated state only through its icon and tooltip, so the immediate tap intent was ambiguous | Added visible green/neutral state, “Live” or “Paused” text, toggle semantics and a 44 px target | Screen 107 clean state → user can identify current availability and the result of each tap without another screen |
| MF-006 | Several screens exposed implementation language and 9–10 px operational labels | Replaced “canonical,” “authoritative,” “role-controlled,” “classification locked” and “protected action” with user-facing outcomes; increased key supporting labels | Screens 107–115 visual and tap replay: wording explains the action/result and compact labels remain readable |

## Exact failed-operation replays

- Supply failure leaves supply Live; the exact second tap pauses it once.
- Invalid product MOQ calls no gateway. Publish failure creates no product;
  the exact retry creates `SKU-109-0719`; duplicate publish creates no second
  product.
- Invalid partial quantity or short cannot-fulfil reason calls no gateway.
  Confirm failure changes no order; exact retry creates `CONF-110-4821`;
  duplicate confirm creates no second outcome.
- An empty input cart calls no gateway. PO failure preserves the cart; exact
  retry creates `PO-IN-111-0719`; duplicate PO is ignored. Receipt creates
  `GRN-111-0719` once.
- Missing dispatch documents and invalid vehicle identity call no gateway.
  Dispatch failure preserves every selection; exact retry creates
  `DSP-112-4821`; buyer receipt creates `POD-112-4821` once.
- Invalid campaign target calls no gateway. The first valid tap reviews the
  campaign; failed publish preserves review; exact retry creates
  `MFG-CMP-113-0719`; duplicate publish is ignored.
- Claim, invite and settings failures create no committed state. Exact retries
  create `MFG-RES-114-0719`, `MFG-INV-114-0719` and `MFG-SET-114-0719` once.
- A service request without accepted terms calls no gateway. Request failure
  creates no entitlement; exact retry creates `MFG-SVC-115-0719`; duplicate
  request is ignored.
- Offline and permission-denied commands call no protected gateway and
  preserve every prior outcome.

## Independent UI/UX enhancement cycle

The second UI/UX cycle began only after the first dedicated, affected and full
regressions were green.

- Added and inspected stable 412 × 915 baselines for all nine screens.
- Replaced the ambiguous toolbar supply icon with a visible Live/Paused state.
- Increased the readability of section details, status pills and metric labels.
- Removed engineering and internal-control wording from user-facing screens.
- Preserved Apple-inspired calm surfaces, restrained hierarchy, 44 px minimum
  controls, compact sub-action rails and the persistent Mool outcome dock.
- Preserved every route, validation, authorization, failure-safe retry and
  idempotency boundary.

## Test and replay results

Before the independent UI/UX enhancement:

- Dedicated screen 107–115 black-box scenarios: 10/10 passed.
- Affected manufacturer journeys: 55/55 passed.
- Full application regression pass 1: 200/200 passed.
- Flutter analyzer: no issues.

After the independent UI/UX enhancement:

- Dedicated screen 107–115 black-box scenarios: 10/10 passed.
- Screen 107–115 visual baselines: 9/9 passed twice.
- Affected functional and visual regression: 64/64 passed.
- Full application regression pass 2: 209/209 passed.
- Flutter analyzer: no issues.
- Physical OPPO CPH2375 exact replay: 1/1 passed twice.
- The second OPPO cycle used `flutter clean`, fresh dependency resolution, a
  new debug APK build and a fresh install.

## Physical OPPO evidence

- Device: OPPO CPH2375, device ID `2b3e0f71`, Android 13.
- Package: `com.moolsocial.app`.
- Exact replay: Home → failed Pause → exact Pause retry → Product Master →
  Masala Tea → quantity/price/MOQ/input mapping → failed Publish → exact
  Publish retry → Order Review → failed Confirm → exact Confirm retry →
  Inputs → cart → failed PO → exact PO retry → receipt → Dispatch → LR →
  failed Confirm → exact retry → delivered → buyer receipt → Growth →
  campaign review → failed Publish → exact retry → Services → accept terms →
  failed Request → exact retry.
- Assertions: one `SKU-109-0719`, `CONF-110-4821`, `PO-IN-111-0719`,
  `GRN-111-0719`, `DSP-112-4821`, `POD-112-4821`,
  `MFG-CMP-113-0719` and `MFG-SVC-115-0719`, with no duplicate protected
  state.
- Screenshot checkpoints are captured by
  `integration_test/manufacturer_device_replay_test.dart`.

## Remaining external blockers

- Catalogue, stock, input mapping, sales orders and Business Book still use
  deterministic review data; production needs server-authoritative product,
  inventory, order and ledger services.
- Buyer advances, supplier payments, receivables, refunds and claim holds need
  production payment-provider and ledger integration.
- Supplier offers, purchase orders, GST documents, LR, e-way bill, tracking
  and delivery proof need real procurement, compliance and logistics services.
- Buyer demand, campaign funding, attribution and worker outcomes need
  production event, consent, fraud, payout and attribution services.
- Team identity, roles, invitations, sessions and permissions need production
  Firebase Authentication, claims and server-side policy.
- Manufacturer services need entitlement, contracting, billing, qualified
  provider and evidence systems.
- The Android build emits a future Flutter migration warning for plugins that
  still apply the Kotlin Gradle Plugin; it is not a current build or runtime
  failure.

## Evidence-based gate

The deterministic Flutter client slice for screens 107–115 is **GO** for
continued full-scale implementation. It is **NO-GO** for public manufacturer
commerce, procurement, dispatch, campaigns, access control or paid services
until the external systems above are connected to server-authoritative
production services and certified in their sandboxes.
