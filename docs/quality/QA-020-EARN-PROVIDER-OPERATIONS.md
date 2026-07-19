# QA-020 — Earn operations and service-provider workspace

Date: 19 July 2026

## Scope

- Approved HTML behavior source: screens 133–146
- Funded opportunities, applications, active work, proof, earnings and history
- Provider home, services, availability, requests, fulfilment, business
  records, growth and controls
- Every visible control, nested sheet, invalid input, cancellation, loading,
  offline, permission-denied, gateway failure, exact retry and duplicate action

## Screen-by-screen tap and nested-tap coverage

| Approved screen | Production intent path | Covered controls and nested outcomes |
|---:|---|---|
| 133 | Find and apply for genuine funded work | Best Match, Onboarding, Campaign, Verification and Delivery filters; every opportunity; output, place, proof, payout, correction, reserved funding and eligibility; close; blocked apply without terms; failed apply; exact retry; duplicate apply; open My Work |
| 134 | Understand application state and start approved work | Applied, Saved and Eligibility; review and close; approved assignment; failed Start Work; exact retry; duplicate start; open Active Work |
| 135 | Complete one bounded assignment safely | Payout, due time and proof; all four work steps; support category; empty support; failed support; exact retry; duplicate support; close; continue to proof |
| 136 | Submit truthful proof for verification | Every proof item; proof help; incomplete proof; truth confirmation; failed submission; exact retry; duplicate submission; held payout; open Earnings |
| 137 | Trace earnings and prepare records | Available, Under Review and Paid totals; every ledger item; source, status and amount; statement type; failed preparation; exact retry; duplicate preparation; open History |
| 138 | Review completed work, issues and growth | History, Issues and Growth; every record; result, proof and payout; support access; deterministic close and return |
| 139 | Enter the correct provider operating area | Requests, Services, Availability, Money, Growth and Controls; priority request, capacity and readiness owners; every card opens its authoritative owner screen |
| 140 | Publish a clear customer service | Live, Draft, Paused and Needs Update; every service; preview and close; add service; invalid fields; name, price, time, scope and visibility; failed save; exact retry; duplicate save |
| 141 | Set truthful capacity without harming accepted work | Capacity, hours and area; every day; service mode; pause and cancel; pause duration; blocked unconfirmed pause; failed save; exact retry; duplicate save |
| 142 | Accept or decline one complete customer request | New, Accepted and Completed; every request; price, time, scope and cancellation; blocked accept; failed accept; exact retry; duplicate accept; invalid decline; failed decline; exact retry; duplicate decline |
| 143 | Fulfil an accepted request and complete its outcome | Progress; customer message; send; privacy; arrival and outcome confirmations; blocked completion; failed completion; exact retry; duplicate completion; settlement amount; open Money |
| 144 | Understand payments and export business records | Payments, Customers, Receipts and Refunds; every record; amount, source and status; Statement, Receipts and Refunds exports; failed export; exact retry; duplicate export |
| 145 | Distinguish earning from buying business growth | Best Match, Earn, Promote and Nearby; funded service work that pays the provider; customer-growth campaign paid by the provider business; payout versus maximum budget; terms; blocked action; failed action; exact retry; duplicate action |
| 146 | Control readiness, people, alerts and support | Identity, document, payment, owner, operations and accounts; every control detail; priority alerts, capacity pause and reminders; failed save; exact retry; duplicate save; invalid support; failed support; exact retry; duplicate support |

## Locked operating rules

- A worker never pays to apply for or start funded work. A verified business or
  MoolSocial reserves the payout for approved output.
- Potential earnings are not salary or guaranteed income. Eligibility, open
  capacity, truthful proof and approved output control payment.
- A failed, offline or unauthorized protected command creates no assignment,
  payout, service, acceptance, completion, export, campaign or support case.
- Applications, starts, proof submissions, statements, service saves,
  availability, request decisions, fulfilment, exports, growth actions,
  control saves and support cases are idempotent and safe to retry.
- Provider growth has two different economic directions:
  - funded work pays the provider after an approved outcome;
  - a growth campaign uses the provider business’s approved maximum budget.
- Submitting a provider growth campaign does not claim a charge. Charging can
  begin only after the external payment provider and business complete final
  confirmation.
- Pausing new demand never cancels already accepted customer work.
- Completing fulfilment requires both arrival and completed-outcome
  confirmation. Settlement remains under review until its external ledger
  confirms it.

## Defects discovered, root cause, fix and exact replay

| Ticket | Defect and root cause | Fix | Exact original replay |
|---|---|---|---|
| OPS-001 | Screen 133 reused the same filter keys in the page and modal, so a tap could resolve to two controls instead of one clean intent | Gave modal filters a separate `earn-filter-sheet-*` key space | Opportunities → Filters → Delivery → Show Opportunities: one filter changes and the sheet closes cleanly |
| OPS-002 | Screen 137 used a fixed-height statement sheet that overflowed on a phone | Made the sheet scroll-controlled with a safe scroll body | Earnings → Prepare Statement → traverse type and action → Close: no clipping or blocked action |
| OPS-003 | Screen 142 request terms used a fixed-height modal and could hide the acceptance action | Made request terms scroll-controlled | Requests → Accept → review every term → confirmation → Accept: all content and the final action remain reachable |
| OPS-004 | Screen 145 growth terms used a fixed-height modal and could hide its primary action | Made growth terms scroll-controlled | Earn and Grow → either card → read all economics → confirm → primary action: no clipping |
| OPS-005 | Screen 145 used “Accept Funded Work” for both an earning opportunity and a provider-funded customer campaign, reversing payer and beneficiary intent | Split title, source, facts, confirmation and result copy by economic direction; a campaign now says “Submit Growth Campaign” and no charge before final confirmation | Growth campaign → review ₹8,000 maximum budget → confirm → fail → exact retry: campaign request is submitted once and never reported as funded work accepted |
| OPS-006 | Screen 133 described reserved funding but did not explicitly remove the trust concern that a worker might have to pay | Added “You never pay to apply or start” and identified the business or MoolSocial as funder | Opportunity → Review → funding explanation: the worker can identify payer, payout and non-guarantee before applying |

## Exact failed-operation replays

- Missing work terms call no gateway. Application failure creates no
  application; exact retry creates `EARN-APP-133-retailer` once.
- Work-start failure creates no active assignment; exact retry creates
  `WRK-4821` once.
- Missing support detail calls no gateway. Support failure creates no case;
  exact retry creates `EARN-CASE-135-4821` once.
- Incomplete proof calls no gateway. Outcome failure creates no submission;
  exact retry creates `EARN-OUTCOME-136-4821` once.
- Statement failure creates no file; exact retry creates
  `EARN-STMT-137-0719` once.
- Invalid service fields call no gateway. Service-save failure creates no
  service; exact retry creates `PROV-SVC-140-0719` once.
- Unconfirmed pause calls no gateway. Availability failure creates no version;
  exact retry creates `PROV-CAP-141-0719` once.
- Missing request terms call no gateway. Accept failure creates no acceptance;
  exact retry creates `PROV-ACCEPT-142-RQ-2401` once.
- Missing decline reason calls no gateway. Decline failure creates no response;
  exact retry creates `PROV-DECLINE-142-RQ-2402` once.
- Missing arrival or outcome confirmation calls no gateway. Fulfilment failure
  creates no completion; exact retry creates `PROV-DONE-143-2401` once.
- Export failure creates no file; exact retry creates
  `PROV-EXPORT-144-RECEIPTS` once.
- Missing economic terms call no gateway. Growth failure creates no request;
  exact retry creates `PROV-GROW-145-campaign` once.
- Control-save failure creates no version; exact retry creates
  `PROV-CONTROL-146-0719` once.
- Missing provider-support detail calls no gateway. Support failure creates no
  case; exact retry creates `SUP-146-2048` once.
- Offline and permission-denied commands preserve user work and call no
  protected gateway.

## Independent UI/UX enhancement cycle

The second UI/UX cycle began only after the first dedicated, affected and full
regressions were green.

- Captured and inspected stable 412 × 915 baselines for all 14 screens.
- Preserved calm Apple-inspired surfaces, readable hierarchy, minimum 44 px
  controls, persistent Mool/Chat access and deterministic return paths.
- Separated “you earn” work from “your business pays” growth.
- Made worker funding and no-fee language explicit before application.
- Removed ambiguous outcome language without adding decorative controls.
- Preserved every validation, authorization, failure, retry and idempotency
  boundary.

## Test and replay results

Before the independent UI/UX enhancement:

- Dedicated screens 133–146 black-box scenarios: 14/14 passed.
- Operations visual baselines: 14/14 passed.
- Affected operations and universal journeys: 85/85 passed.
- Full application regression pass 1: 279/279 passed.
- Flutter analyzer: no issues.

After the independent UI/UX enhancement:

- Dedicated screens 133–146 black-box scenarios: 14/14 passed.
- Operations visual baselines: 14/14 passed twice.
- Affected functional and visual regression: 85/85 passed.
- Full application regression pass 2: 279/279 passed.
- Flutter analyzer: no issues.
- Physical OPPO CPH2375 exact replay: 1/1 passed twice.
- The second OPPO cycle used `flutter clean`, fresh dependency resolution, a
  new debug APK build and reinstall.

## Physical OPPO evidence

- Device: OPPO CPH2375, device ID `2b3e0f71`, Android 13.
- Package: `com.moolsocial.app`.
- Exact replay: Funded Opportunity → failed Apply → exact retry → approved
  Application → failed Start → exact retry → Active Work → failed Support →
  exact retry → Proof → failed Submit → exact retry → Earnings → failed
  Statement → exact retry → Service → failed Save → exact retry →
  Availability → failed Save → exact retry → Request → failed Accept → exact
  retry → Fulfilment → failed Complete → exact retry → Money → failed Export
  → exact retry → Growth → failed Submit → exact retry → Controls → failed
  Save → exact retry → failed Support → exact retry.
- Assertions: every protected ID listed above exists once and all 13
  failed/retried gateway counters equal exactly two.
- Screenshot checkpoints are captured by
  `integration_test/operations_device_replay_test.dart`.
- Each physical replay mounted a new in-memory signed-in journey and injected
  a new gateway, so every outcome ID was empty before its first failed action.

## Remaining external blockers

- Opportunity funding, business identity, worker eligibility, geofencing,
  proof validation and fraud decisions still use deterministic review data.
- Real task dispatch, capacity reservation, messaging, maps/location and
  customer privacy need production services and policy approval.
- Provider identity, documents, staff roles, catalogue publication,
  availability and request state need live backend authorization and audit.
- Payments, fund reservation, settlement, refunds, tax treatment, payout and
  exports need provider sandbox certification and immutable production ledger
  controls.
- Customer-growth attribution, maximum-budget enforcement, charging,
  cancellation and expiry need production campaign and payment services.
- Support cases need production queues, service-level targets and staffed
  escalation.
- The Android build emits a future Flutter migration warning for plugins that
  still apply the Kotlin Gradle Plugin; it is not a current build or runtime
  failure.

## Evidence-based gate

The deterministic Flutter Earn and provider slice for screens 133–146 is
**GO** for continued full-scale implementation. It is **NO-GO** for public
funded assignments, service publication, customer fulfilment, provider-funded
growth, settlement, export or payout until the external systems above are
connected to production services and certified in their sandboxes.
