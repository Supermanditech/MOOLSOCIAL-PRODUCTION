# QA-018 — Captain rides, earnings, compliance and opportunities

Date: 19 July 2026

## Scope

- Approved HTML behavior source: screens 116–123
- Captain availability, ride request, pickup, trip, fare and payment
- Earnings, payout, vehicle compliance, safety and support
- Separate paid opportunities without mixing delivery-partner work
- Every visible control, nested sheet, invalid input, cancellation, loading,
  offline, permission-denied, gateway failure, exact retry and duplicate action

## Screen-by-screen tap and nested-tap coverage

| Approved screen | Production intent path | Covered controls and nested outcomes |
|---:|---|---|
| 116 | Choose availability and continue the highest-priority Captain action | Go Online/Offline with failure and exact retry; live-location explanation; demand zones; new-request review; state-aware current Trip; Earnings; Insurance renewal; Captain controls; Support & Opportunities; Requests, Trip, Earnings, Mool and Chat dock routes |
| 117 | Decide on one ride with the complete route and earnings visible first | Pause requests; cancel and confirm pause; blocked accept while paused; route; pickup; destination; rider identity/rating; fare, platform charge, fuel estimate and expected net; failed Accept; exact retry; duplicate Accept; failed Decline; exact retry; duplicate Decline; no assignment after decline |
| 118 | Reach pickup, contact the rider and start the correct trip | Route map; masked Call cancel/connect; Chat; Support; stale-location rejection; confirm pickup arrival; cancelled OTP sheet; incomplete OTP; wrong OTP; failed valid OTP start; exact retry; duplicate start |
| 119 | Operate a live trip and finish only at the destination | Route and ETA; Trip options; SOS; Issue; Rider Chat; support continuation; stale destination-location rejection; failed arrival; exact retry; duplicate arrival; state-aware Trip dock |
| 120 | Review final fare, confirm payment and reach earnings | Fare breakdown; customer payment method; Payment Help; failed payment check; exact retry; duplicate check; payment receipt; close; View Earnings |
| 121 | Understand earnings and payout at trip level | Today, This Week and Payouts; statement download; automatic payout details; open statement; every recent trip; gross fare, platform charge, net earning and payment status; close |
| 122 | Keep the vehicle eligible with the correct records | Add/update document; every Driving Licence, RC, insurance, PUC and permit record; close; insurance renewal; required consent; failed verification; exact retry; duplicate verification |
| 123 | Resolve a problem, apply for paid work or care for the vehicle | Support, Opportunities and Vehicle Help tabs; every support category; short-description rejection; failed support case; exact retry; duplicate case; every opportunity; application without terms; failed application; exact retry; duplicate application; every vehicle-help option; insurance route; Pay route; service comparison |

## Locked operating rules

- Location sharing for new rides begins only after the Captain chooses Online
  and stops after choosing Offline.
- A ride cannot be accepted while requests are paused. Route, pickup distance,
  fare, charges, fuel estimate and expected earning remain visible before the
  decision.
- Accept and decline are mutually exclusive, idempotent decisions.
- Trip start requires confirmed pickup location and the matching rider OTP.
- Fare completion requires a started trip and current destination location.
- A failed payment check never closes the trip or credits earnings. The same
  action can safely retry and one receipt credits one earning.
- The persistent Trip action follows the actual state: pickup, live trip or
  fare completion. It never restarts the journey at pickup.
- Compliance actions disclose the selected record and require explicit consent
  before verification.
- Support cases attach relevant Captain, vehicle and trip context without
  exposing internal implementation terms.
- Paid opportunities disclose geography, payment, payment rule, proof and
  remaining availability before application.
- Delivery work requires the separate Delivery Partner workspace.
- Offline and unauthorized commands never reach a protected gateway.

## Defects discovered, root cause, fix and exact replay

| Ticket | Defect and root cause | Fix | Exact original replay |
|---|---|---|---|
| CAP-001 | Fixed-width Earnings and Support tab rows could not contain “This Week”, “Paid Work” and “Vehicle Help” at compact width | Rebuilt both as horizontally scrollable 44 px action rails | Screens 121 and 123 at 412 px → traverse every tab: no overflow and every tab completes |
| CAP-002 | The payout sheet used a fixed-height modal body and exceeded the available phone height | Made the sheet scroll-controlled with a bounded scroll body | Screen 121 → payout/statement → inspect all details and close: no clipping or blocked action |
| CAP-003 | The offline audit fixture preloaded completed command IDs, allowing idempotent duplicate handling to look like an offline pass | Tested every offline command from an uncompleted clean state and injected only the prerequisite from the preceding command | Clean state → Offline → every protected action: all return false and every gateway counter stays zero |
| CAP-004 | The persistent Trip action always opened pickup, even after trip start or destination arrival | Added one state-derived current-trip route and used it in the dock and home priority action | Pickup → Trip opens pickup; Live → Trip opens live route; payment pending/completed → Trip opens fare completion |
| CAP-005 | Several labels described implementation or state instead of the user’s next action: “GPS freshness”, “reconciled”, “resolved” and generic “Open” | Replaced them with “Location updated”, “Ready for payout”, approved-service wording and intent-specific Continue, Renew, Start, Get Help and Review actions | Screens 116, 119, 122 and 123 → read and tap each revised action: the named outcome opens directly |
| CAP-006 | Paid-opportunity facts and map pins used 9–10 px supporting text | Increased important compact labels and values while retaining bounded wrapping | Screens 118, 119 and 123 at 412 × 915: supporting facts remain legible with no overflow |

## Exact failed-operation replays

- Availability failure leaves the Captain Offline; the exact second tap goes
  Online once.
- Accept failure creates no assignment; the exact retry creates
  `CAP-ASG-117-4821`; a duplicate creates no second assignment.
- Decline failure creates no decision; the exact retry creates
  `CAP-DEC-117-4821`; no assignment exists.
- Stale pickup location, incomplete OTP and incorrect OTP call no start
  gateway. Start failure keeps the pickup state; exact retry creates
  `CAP-START-118-4821` once.
- Stale destination location calls no arrival gateway. Arrival failure keeps
  the live trip; exact retry creates `CAP-ARR-119-4821` once.
- Payment failure creates no receipt or earning; exact retry creates
  `CAP-PAY-120-4821` once and exposes View Earnings.
- Missing document consent calls no gateway. Verification failure creates no
  request; exact retry creates `CAP-VER-122-0719` once.
- A short support description calls no gateway. Support failure creates no
  case; exact retry creates `CAP-CASE-123-0719` once.
- Missing opportunity terms call no gateway. Application failure creates no
  application; exact retry creates `CAP-WORK-123-0719` once.
- Offline and permission-denied commands preserve all prior state and call no
  protected gateway.

## Independent UI/UX enhancement cycle

The second UI/UX cycle began only after the first dedicated, affected and full
regressions were green.

- Captured and inspected stable 412 × 915 baselines for all eight screens.
- Made Trip navigation follow the latest usable trip step.
- Replaced operational wording and vague actions with immediate user outcomes.
- Made insurance renewal explicit and renamed the mixed Support page to
  Support & Opportunities.
- Increased compact supporting-text readability.
- Preserved Apple-inspired calm surfaces, restrained color, clear hierarchy,
  44 px controls, persistent Mool/Chat access and compact action rails.
- Preserved every route, validation, authorization, retry and idempotency
  boundary.

## Test and replay results

Before the independent UI/UX enhancement:

- Dedicated screen 116–123 black-box scenarios: 10/10 passed.
- Affected Captain and universal journeys: 80/80 passed.
- Full application regression pass 1: 219/219 passed.
- Flutter analyzer: no issues.

After the independent UI/UX enhancement:

- Dedicated screen 116–123 black-box scenarios: 10/10 passed.
- Screen 116–123 visual baselines: 8/8 passed twice.
- Affected functional and visual regression: 88/88 passed.
- Full application regression pass 2: 227/227 passed.
- Flutter analyzer: no issues.
- Physical OPPO CPH2375 exact replay: 1/1 passed twice.
- The second OPPO cycle used `flutter clean`, fresh dependency resolution, a
  new debug APK build and a fresh install.

## Physical OPPO evidence

- Device: OPPO CPH2375, device ID `2b3e0f71`, Android 13.
- Package: `com.moolsocial.app`.
- Exact replay: Captain Home → failed Go Online → exact retry → Ride Request →
  failed Accept → exact retry → Pickup → rider OTP → failed Start → exact
  retry → Live Trip → failed destination arrival → exact retry → Fare →
  failed payment check → exact retry → Earnings → Insurance → failed
  verification → exact retry → Support → failed case → exact retry →
  Opportunity → failed application → exact retry.
- Assertions: one `CAP-ASG-117-4821`, `CAP-START-118-4821`,
  `CAP-ARR-119-4821`, `CAP-PAY-120-4821`, `CAP-VER-122-0719`,
  `CAP-CASE-123-0719` and `CAP-WORK-123-0719`; every failed/retried gateway
  was called exactly twice and produced no duplicate protected state.
- Screenshot checkpoints are captured by
  `integration_test/captain_device_replay_test.dart`.

## Remaining external blockers

- Captain identity, ratings, vehicle eligibility, requests, assignments and
  trip state still use deterministic review data; production needs live
  identity, dispatch and trip services.
- Pickup/destination geofencing, navigation, location consent and background
  location need production Maps/location integration and real-device
  permission certification.
- Masked calling, rider messaging, emergency escalation and incident handling
  need communications and safety providers with audited response procedures.
- Fare, UPI/cash status, receipts, earnings, adjustments and payouts need
  payment-provider, ledger, reconciliation and payout integrations.
- Driving Licence, RC, insurance, PUC and permits need DigiLocker/document,
  expiry, fraud and jurisdiction-rule integrations.
- Paid opportunities need live capacity, evidence review, worker identity,
  fraud controls and payout services.
- The Android build emits a future Flutter migration warning for plugins that
  still apply the Kotlin Gradle Plugin; it is not a current build or runtime
  failure.

## Evidence-based gate

The deterministic Flutter client slice for screens 116–123 is **GO** for
continued full-scale implementation. It is **NO-GO** for public ride matching,
live navigation, fare collection, payouts, emergency response, document
eligibility or paid opportunities until the external systems above are
connected to server-authoritative production services and certified in their
sandboxes.
