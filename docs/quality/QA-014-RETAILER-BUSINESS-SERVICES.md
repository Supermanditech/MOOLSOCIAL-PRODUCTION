# QA-014 — Retailer Business Services, activation and operating home

Date: 19 July 2026

## Scope

- Approved HTML behavior source: screens 93, 94, 95 and 96
- MoolSocial-operated Delivery Support, Grow Sales, Tax & Books and Offers &
  Ads outcomes
- Independent service detail, plan, spend limit, payment, consent,
  activation, operation, support and cancellation paths
- Exact monthly fee, included work, additional charge, non-billable event,
  proof rule, tax, renewal and maximum-spend disclosure
- Validated ₹1,500, ₹3,000 and custom monthly limits
- UPI AutoPay, saved-card mandate and manual monthly renewal
- Commercial consent that is never preselected
- Separate purpose-limited business-data consent for Tax & Books
- Idempotent payment and entitlement activation
- Service-specific usage, spend, setup, next work, activity, billing and
  support
- Loading, invalid, empty, duplicate, cancelled, retry, offline,
  role-denied, gateway-failure, compact-width and larger-text outcomes

## Screen-by-screen tap and nested-tap coverage

| Approved screen | Production intent path | Covered controls and nested outcomes |
|---:|---|---|
| 93 | Choose one operated business outcome | Back; help; active count; refresh; Delivery Support, Grow Sales, Tax & Books and Offers & Ads; every decisive detail sheet; close; outside/cancel; Not now; exact starting fee, variable charge, included outcome, proof and non-charge facts; View plans; empty catalogue; offline; role denial; refresh failure and exact retry |
| 94 | Compare the selected service and set maximum spend | Back; protection help; Starter and Growth plan for every service; exact monthly, included, additional, charged/not-charged and service-area/access rules; ₹1,500; ₹3,000; Custom; invalid text; below-minimum custom amount; above-protection maximum; valid custom amount; retained selection after plan-load failure; exact retry; Review activation |
| 95 | Authorize exact commercial terms and activate once | Back; help; due-now charge; later charge after proof; monthly cap; renewal; service terms and reviewed state; UPI AutoPay; Visa mandate; manual monthly payment; required commercial consent; separate Tax & Books data consent; disabled activation before consent; payment failure; exact retry; retained plan, limit, payment and consent; duplicate submission protection |
| 96 | Operate the active service instead of reaching a receipt dead end | Back; service menu; entitlement and payment proof; plan and renewal; included use; remaining use; spend/limit; additional charge; service-specific first work; every quick setup item; ready/duplicate setup state; setup failure and retry; auditable activity; Plan & billing; Service support; support failure and retry; Chat thread and protected return; Stop renewal; Keep service; cancellation failure and retry |

## Independent service outcomes

| Service | First useful work | Initial setup | Evidence boundary |
|---|---|---|---|
| Delivery Support | Open a packed customer order | Pickup hours, zones and delivery rules | Pickup plus accepted-delivery proof |
| Grow Sales | Create a sales campaign | Area, offer and field team | Paid, non-refunded attributed order |
| Tax & Books | Connect authoritative Business Book records | Books, documents and logged access | Acknowledgement or accepted work record |
| Offers & Ads | Create a shop offer or campaign | Offer, approved budget and attribution | Spend report plus paid attributed order |

All four services create separate entitlements and can be cancelled
independently. Activating one never silently activates or bundles another.

## Defects discovered and exact failed-tap replays

| Ticket | Defect and root cause | Fix | Exact original replay |
|---|---|---|---|
| BS-001 | Entering Screen 94 notified `RetailerSession` from `initState` while the route tree was still building, causing a build-phase crash | Deferred plan loading and session notification to the first post-frame callback | Screen 93 → Delivery Support → View plans: Screen 94 renders, loads and returns without an exception |
| BS-002 | The active-service CTA inherited the theme’s full-width button constraint inside a horizontal row, producing infinite-width layout failures | Added an explicit bounded CTA width and scale-down label behavior | Consent → failed activation → exact Pay & activate retry → Screen 96: entitlement and CTA render without layout error |
| BS-003 | Service support correctly opened a Chat thread, but the failed replay assumed one Back tap returned to the service; Chat architecture intentionally returns through Inbox | Preserved the protected two-step return contract and added it to the exact regression | Screen 96 → Service support → Order Support → Back to Inbox → Back to same active service |
| BS-004 | Side-by-side plan cards wrapped commercial copy excessively and delayed useful comparison | Replaced them with full-width selected plan rows with separate included work, variable charge and price columns | Screen 94 at 412 × 915: both plans are decisive, readable and retain the exact same tap keys |
| BS-005 | The active entitlement and split metrics consumed too much of the first viewport | Compressed the entitlement proof, aligned all three metrics in one row and moved the first useful work plus setup into the initial viewport | Screen 96 at 412 × 915 and physical OPPO: entitlement, spend truth, next work and setup render together |

## Exact failed-operation replays

- Catalogue refresh failure retains the current service facts; exact refresh
  succeeds.
- Plan-load failure retains the selected service and plan; exact load succeeds.
- Custom limit rejects non-numeric, below ₹1,000, below selected-plan and
  above ₹1,00,000 values.
- Activation cannot start without required commercial consent.
- Tax & Books additionally cannot start without separate business-record
  access consent.
- Payment failure collects no payment, creates no entitlement and retains
  every selection; the exact retry creates one entitlement.
- Duplicate activation creates neither a second payment nor a second
  entitlement.
- Offline and unauthorized roles cannot activate or change paid services.
- Failed setup changes no readiness state; exact retry records it once.
- Repeated setup reports the existing Ready state without duplication.
- Failed support does not alter the active service; exact retry opens the
  support thread.
- Failed cancellation leaves the entitlement active; exact retry stops renewal
  and removes only the selected service.

## UI/UX enhancement cycle

The required independent post-test enhancement cycle was completed after the
first clean black-box, affected and full-regression results.

- Added stable 412 × 915 visual baselines for screens 93–96.
- Inspected all four rendered screens as one commercial lifecycle.
- Replaced cramped two-column plan choices with full-width selection rows.
- Reduced active-entitlement height while preserving plan, mandate and renewal
  proof.
- Aligned included usage, spend cap and additional charges in one compact row.
- Brought the first useful service action and readiness setup into the initial
  active-service viewport.
- Preserved every production key, route, price, consent and failure boundary.

## Test and replay results

Before the independent UI/UX enhancement:

- Dedicated service scenarios: 8/8 passed.
- Affected retailer journeys and existing goldens: 46/46 passed.
- Full application regression cycle 1: 158/158 passed.
- Full application regression cycle 2 from a fresh process: 158/158 passed.
- Flutter analyzer: no issues.
- Physical OPPO CPH2375 activation replay: 1/1 passed.

After the independent UI/UX enhancement:

- Dedicated service scenarios: 8/8 passed.
- New screen 93–96 visual baselines: 4/4 passed twice.
- Affected retailer functional and visual regression: 50/50 passed.
- Final full application regression: 162/162 passed.
- Flutter analyzer: no issues.
- Enhanced physical OPPO CPH2375 activation replay: 1/1 passed.

## Physical OPPO evidence

- Device: OPPO CPH2375, device ID `2b3e0f71`.
- Package: `com.moolsocial.app`.
- Exact replay: Business Services → Offers & Ads → Growth plan → custom
  ₹12,000 cap → Visa mandate → terms → commercial consent → Pay & activate →
  active entitlement → Offer setup → first campaign setup.
- Assertions: one Ads entitlement, Growth plan, ₹12,000 maximum, card mandate,
  ready Offer setup and no duplicate payment.
- Screenshot checkpoints are captured by
  `integration_test/retailer_business_services_device_replay_test.dart` for
  screens 93, 94, 95 and 96.

## Remaining external blockers

- Plan catalogue, eligibility, taxes, pricing versions and service areas still
  use the deterministic review gateway.
- Live UPI/card mandate collection and payment idempotency need the certified
  payment-provider sandbox and production backend.
- Entitlements, usage, spend caps, cancellation and activity proof need the
  production datastore and server authorization.
- Delivery assignment, attributed sales, advertising spend, tax filings,
  evidence storage and service-professional verification need their real
  provider workflows.
- The build emits a future Flutter migration warning for plugins that still
  apply the Kotlin Gradle Plugin; it is not a current build or runtime failure.

## Evidence-based gate

The deterministic Flutter client slice for screens 93–96 is **GO** for
continued full-scale implementation. It is **NO-GO** for public paid-service
activation until payment, server-priced plans, entitlements, usage evidence,
regulated-professional authorization and cancellation are connected to
certified production services. The client now supplies exact contracts,
failure replays and regression gates for that integration.
