# QA-021 — Superadmin operations and dynamic provisioning

Date: 19 July 2026

## Scope

- Separate, role-gated Next.js Superadmin for approved screens 147–156 and
  163–164
- 42 operating cases across command, verification, catalogue, commerce, rides,
  work, trust, finance, support, launch, product health and signals
- Profile-specific provisioning for the permanent personal profile and all 28
  approved workspace profiles
- Business-funded Reel provisioning with sponsor disclosure and a controlled
  1, 2, 3, 4, 5, 6 or 7 day duration
- Every filter, search result, empty state, navigation owner, case modal,
  confirmation, primary action, alternative action, cancelled state, loading,
  failed action, exact retry, duplicate action, offline and permission-denied
  outcome

## Screen-by-screen tap and nested-tap coverage

| Screen | Cases | User intent completed |
|---:|---:|---|
| 147 | 3 | Triage payment, ride-safety and order-capacity incidents; open evidence; confirm; contain or acknowledge; open the accountable owner |
| 148 | 3 | Decide grocery-retailer, doctor and restaurant verification with profile-specific evidence and specialist boundaries |
| 149 | 3 | Review canonical SKU, duplicate catalogue and regulated-product governance without publishing an unsafe change |
| 150 | 3 | Resolve stock mismatch, delivery delay and cancellation exceptions while preserving customer and money state |
| 151 | 3 | Operate SOS, pickup-delay and fare-review cases with trip, safety and payment context |
| 152 | 3 | Govern funded campaigns, proof outcomes and appeals without promising unapproved earnings |
| 153 | 3 | Review medical claims, rights matches and paid-disclosure defects with reason, duration and appeal |
| 154 | 3 | Reconcile unmatched payments, protected advances and refund batches without duplicate money movement |
| 155 | 3 | Resolve damaged groceries, toll disputes and worker appeals with evidence and an independent path |
| 156 | 5 | Configure, approve, test, pause or release offerings; create a profile-specific approval draft; preserve funding and eligibility boundaries |
| 163 | 5 | Trace payment, transfer, release, action-coverage and support health to one responsible owner |
| 164 | 5 | Govern commerce, work, proximity, compliance and safety signals without exporting private audience lists |

Every screen also covers every visible filter, an impossible search, empty-state
recovery and deterministic navigation to all 12 screen owners. All 42 case
dialogs cover blocked unconfirmed action, one-shot failure, exact retry,
duplicate prevention, alternative action where available, close and reopen.

## Locked operating rules

- Superadmin is a separate deployment and is never embedded in the Android/iOS
  client or the public marketing site.
- Production access is denied by default. Review mode is isolated,
  deterministic and cannot reach production data.
- A production command requires a verified server session, least-privilege
  role, reason, permitted scope, evidence and immutable audit record.
- The offering composer targets exactly 29 approved profiles: one personal
  profile plus 28 workspace profiles.
- A draft is not live and charges no budget. Product, Finance, policy and
  Operations approval precede a small test group and health-gated expansion.
- Native creator Reels are business-funded and time-bound. The controlled
  duration is 1–7 days; 1 day is shown as 24 hours and 2 days as 48 hours.
- Failed, offline, unauthorized and duplicate commands preserve prior state and
  cannot create an incident outcome, moderation action, finance action,
  offering or audience release.
- Audience resolution happens when a permitted action is used. Administrators
  cannot export raw audience lists.

## Defects, root causes, fixes and exact replays

| Ticket | Defect and root cause | Fix | Exact replay |
|---|---|---|---|
| ADM-001 | The first live browser replay rendered the page but client actions failed because the development host was not permitted across the local review origin | Allowed only the required localhost review origins and kept production access unchanged | Command → payment incident → confirm → fail → exact retry: one action reference is created and every nested control responds |
| ADM-002 | Offering targets exposed 15 broad labels rather than the approved personal plus 28 workspace registry | Reconciled all 29 exact profile labels and added a permanent count/representative-profile contract | Launch → Create offering → Target: 30 options including the placeholder; all 29 approved profiles are selectable |
| ADM-003 | Product-health copy exposed internal “adapter” and “API” wording | Replaced it with “payment connector” and “responsible service” while retaining accountable ownership | Product Health → payment completion or action coverage: the operator sees a production decision, not implementation shorthand |
| ADM-004 | Dense fact labels used an 8 px type size | Raised fact labels to 10 px and regenerated desktop/mobile baselines | Any queue card or modal → facts: labels remain legible without horizontal overflow |
| ADM-005 | A generic expiry field could accept ambiguous Reel duration text | Added the explicit Business-funded Reel type and controlled 1–7-day choices with 24/48-hour clarification | Launch → Create offering → Shorts Creator → Business-funded Reel → 2 days (48 hours) → Review |
| ADM-006 | Initial visual coverage stopped at the 12 owner pages | Added desktop and mobile baselines for case action, funded-Reel composer and funded-Reel review | Open each nested surface at desktop and mobile sizes: no clipping, overflow or unreachable primary action |

## Exact failure replays

- Every one of the 42 primary case actions is first blocked without
  confirmation, then fails once, then succeeds once on exact retry, and then
  reports that no duplicate was created.
- Every available alternative action follows the same failed/retried/duplicate
  lifecycle.
- Offering creation first rejects missing fields, then rejects missing promise
  confirmation, then fails once while preserving input, then creates
  `OFR-DRAFT-156-0719` once. A repeat confirms that no budget was charged.
- Offline and permission-denied commands produce no protected outcome.
- Physical OPPO cycles 1 and 2 each started with a clean page state and replayed
  Shorts Creator → Business-funded Reel → 2 days (48 hours) → invalid draft →
  confirmed draft → injected failure → exact retry → duplicate protection.

## Regression and evidence

- Contract tests: 6/6 passed.
- Type check and lint: passed.
- Production dependency audit: 0 vulnerabilities.
- Browser black-box regression: 32/32 passed on desktop and mobile Chromium.
- Responsive visual regression: 30/30 passed after baseline generation, then
  30/30 passed again without updating evidence.
- Existing Flutter full regression before this slice: 279/279 passed.
- Existing Flutter full regression after this slice: 279/279 passed.
- Physical OPPO CPH2375 business-funded-Reel exact replay: passed twice.
- Device screenshots:
  - `artifacts/quality/superadmin/oppo-business-funded-reel-cycle-1.png`
  - `artifacts/quality/superadmin/oppo-business-funded-reel-cycle-2.png`
- Stable desktop/mobile evidence for all 12 owner screens and six nested
  surfaces is stored with the Playwright visual specifications.

## Remaining external blockers

- Firebase production session verification and server-side Superadmin role
  claims are not connected while Google Cloud billing activation is unresolved.
- Production commands still need live authorized services, immutable audit
  storage, staffed owner queues and alert delivery.
- Payment, refund and payout operations need provider sandbox certification and
  ledger reconciliation.
- Verification, catalogue, ride safety, proof, moderation and appeal decisions
  need policy approval, specialist operations and production evidence services.
- Offering eligibility, budget reservation, charging, canary delivery,
  measurement, stop conditions and audience resolution need production
  campaign services.

## Evidence-based gate

The deterministic Superadmin operations and profile-specific provisioning slice
is **GO** for continued full-scale implementation and stakeholder review. It is
**NO-GO** for production administrator access, money movement, moderation,
verification or live audience launch until the external blockers above are
connected and certified.
