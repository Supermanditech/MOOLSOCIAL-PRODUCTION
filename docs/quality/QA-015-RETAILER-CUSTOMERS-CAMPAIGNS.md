# QA-015 — Retailer customers, loyalty, reminders and campaigns

Date: 19 July 2026

## Scope

- Approved HTML behavior source: screens 97, 98, 99 and 100
- Customer search, repeat purchase timing, dues, open issues and current
  messaging permission
- Customer detail, repeat basket, current price and stock boundary, invoice
  history and resolved issue evidence
- Purpose-limited Mool Chat and permitted WhatsApp reminders
- Reminder idempotency and the rule that messaging never creates an order
- Active, paused, draft, completed and loyalty campaign views
- Paid, non-refunded order attribution; stock, order and spend caps
- Four-step Outcome → Products → Audience → Review campaign builder
- Draft, publish, pause and delete lifecycle
- Invalid, empty, duplicate, cancelled, loading, retry, offline,
  unauthorized and gateway-failure outcomes

## Screen-by-screen tap and nested-tap coverage

| Approved screen | Production intent path | Covered controls and nested outcomes |
|---:|---|---|
| 97 | Find a customer or prepare a permission-aware repeat offer | Back; campaign action; search; voice search; All, Repeat, Due, Allowed and Issue filters; empty result; empty recovery; repeat-offer hero; all four customer cards; Repeat baskets; Loyalty; permitted-customer tool; refresh failure; exact refresh retry; offline; role denial |
| 98 | Review one customer and complete the next permitted action | Back; Chat; profile; current permission rows; Mool Chat; WhatsApp; disabled SMS; invoices independent of marketing; current repeat basket; Edit basket; Create order; two Sales Book invoice links; resolved issue proof; reminder message edit; short/invalid message; channel change; failed send; exact retry; duplicate send; message log; open-issue and permission-denied suppression |
| 99 | Understand results and operate every campaign state | Back; service help; refresh; Create; All, Active, Drafts, Completed and Loyalty filters; empty state; Use again; active detail; pause; Keep active cancellation; pause failure; exact pause retry; duplicate pause; draft Continue; delete; Keep draft cancellation; delete failure; exact delete retry; completed locked result |
| 100 | Build and publish one protected campaign | Back; Save draft; duplicate draft; draft failure and exact retry; all four objectives; campaign name; stock search; scanner; all three products; last-product protection; all three benefits; invalid and stock-exceeding maximum orders; all four audiences; 5/8 km; 7/14/30 days; MoolSocial/permitted WhatsApp; all four progress steps; Back/Continue; ₹100 minimum and ₹1,00,000 maximum spend; review; failed publish; exact publish retry; duplicate publish |

## Locked customer and campaign rules

- Invoices remain available independently of marketing consent.
- Promotions use only the customer’s current channel permission and retain
  purpose, operator, channel and opt-out evidence.
- An open customer issue can suppress promotion until it is resolved.
- A reminder creates no order and duplicate submission creates no second
  message.
- A repeat basket uses current stock and current price before order creation.
- Campaign maximum orders cannot exceed the lowest selected sellable stock.
- Stock is committed only when an order is accepted.
- Campaign spend cannot exceed the retailer-approved cap.
- Views, visits and unverified leads are not attributed sales.
- Only paid, non-refunded attributed orders count as campaign sales.
- A completed campaign’s final attribution remains locked.
- Verified operated teams are accessed through the service, not exposed as a
  worker or creator directory.

## Defects discovered and exact failed-tap replays

| Ticket | Defect and root cause | Fix | Exact original replay |
|---|---|---|---|
| RC-001 | The Screen 99 Create control inherited the theme’s full-width button constraint inside a trailing row, forcing infinite width | Replaced it with a bounded Apple-inspired Create capsule | Screen 99 clean entry → Create: campaign builder opens without layout failure |
| RC-002 | The Screen 100 Back control was unbounded beside a flexible Continue button and inherited infinite minimum width | Put Back in an explicit flexible region so both actions share finite width | Outcome → Continue → Products: Back and Continue render and each completes its intent |
| RC-003 | The Business Services regression still expected the retired Growth/Ads placeholder sheet | Updated the contract test to require the real Screen 100 campaign route and protected return to the active service | Active Grow Sales → first useful work: real campaign builder opens; service lifecycle continues after return |
| RC-004 | The initial repeat-offer hero placed explanatory copy and its action in competing narrow columns | Rebuilt it as a compact outcome row plus full-width action row | Screen 97 at 412 × 915 and OPPO: timing, permission basis and Prepare offer intent are readable together |
| RC-005 | Campaign reuse used the same narrow side-action pattern | Rebuilt reuse as an outcome summary plus full-width “Use this proven setup again” action | Screen 99 at 412 × 915: performance proof and reuse action remain decisive in the first viewport |
| RC-006 | Filter query parameters could schedule the same post-frame state update after every route rebuild | Compare requested and current filter before scheduling one update | Open `/customers?filter=allowed` and `/campaigns?filter=loyalty`: one state change, stable route and no rebuild loop |

## Exact failed-operation replays

- Customer refresh failure retains current customer, order, issue, due and
  permission records; exact retry succeeds.
- Offline customer refresh calls no gateway and changes no record.
- SMS and non-permitted promotion are rejected while invoices remain
  independent.
- Reminder gateway failure creates no message and no order; exact retry sends
  `MSG-98071` once; duplicate submit creates neither a second message nor an
  order.
- Pause cancellation keeps the campaign active. Pause failure also keeps it
  active; exact retry pauses it; duplicate pause is idempotent.
- Delete cancellation keeps the draft. Delete failure keeps the draft; exact
  retry removes only that draft.
- Empty campaign name blocks Continue and draft creation.
- Removing the last selected product is blocked.
- Maximum orders above the lowest selected sellable stock are rejected.
- Draft failure creates no draft and retains every choice; exact retry creates
  one; duplicate save creates no second draft.
- Publish failure commits no stock, budget or campaign; exact retry creates one
  active campaign; duplicate publish creates no second campaign.
- Offline and unauthorized draft/publish paths call no gateway and preserve all
  state.

## Independent UI/UX enhancement cycle

The required enhancement began only after the first black-box, affected and
full-regression passes were clean.

- Added stable 412 × 915 visual baselines for screens 97–100.
- Inspected customer list, customer detail, campaign operations and final
  campaign review as one end-to-end operating flow.
- Replaced crowded hero/action columns with compact outcome cards and
  full-width intent rows.
- Added a visible bounded Create capsule to campaign operations.
- Added a persistent numbered “Step n of 4” context capsule to the campaign
  builder.
- Kept the usual basket, current permission and next useful action inside the
  first customer-detail viewport.
- Preserved every production key, business rule, route and failure boundary.

## Test and replay results

Before the independent UI/UX enhancement:

- Dedicated customer/campaign black-box scenarios: 10/10 passed.
- Affected retailer journeys: 53/53 passed.
- Full application regression pass 1: 172/172 passed.
- Flutter analyzer: no issues.

After the independent UI/UX enhancement:

- Dedicated customer/campaign black-box scenarios: 10/10 passed.
- New screen 97–100 visual baselines: 4/4 passed twice.
- Affected retailer functional and visual regression: 57/57 passed.
- Full application regression pass 2: 176/176 passed.
- Flutter analyzer: no issues.
- Enhanced physical OPPO CPH2375 replay: 1/1 passed twice from fresh APK
  build/install cycles.

## Physical OPPO evidence

- Device: OPPO CPH2375, device ID `2b3e0f71`.
- Package: `com.moolsocial.app`.
- Exact replay: Customers → Sharma Family → permitted reminder → Back →
  Offers & Campaigns → Create → Products → Free delivery → permitted WhatsApp
  → Review → Publish.
- Assertions: one `MSG-98071`, no order created by messaging, one
  `CMP-10001`, one new active campaign and no duplicate state.
- Screenshot checkpoints are captured by
  `integration_test/retailer_campaign_device_replay_test.dart` for screens
  97, 98, 99 and 100.

## Remaining external blockers

- Customer, order, due, issue, consent and opt-out records still use the
  deterministic review data source.
- Live Mool Chat delivery and permitted WhatsApp require their production
  messaging providers and delivery-status webhooks.
- Product availability, stock commitment, refund status and attribution need
  server-authoritative inventory and order ledgers.
- Campaign drafts, budgets, caps, audience evaluation, pause and final
  attribution lock need production datastore transactions and authorization.
- Operated sales/creator teams, advertising spend and evidence need real
  provider workflows.
- The build emits a future Flutter migration warning for plugins that still
  apply the Kotlin Gradle Plugin; it is not a current build or runtime failure.

## Evidence-based gate

The deterministic Flutter client slice for screens 97–100 is **GO** for
continued full-scale implementation. It is **NO-GO** for public messaging or
paid campaign operation until consent, messaging, inventory, payments,
attribution, budgets, refunds and evidence are connected to server-authoritative
production services.
