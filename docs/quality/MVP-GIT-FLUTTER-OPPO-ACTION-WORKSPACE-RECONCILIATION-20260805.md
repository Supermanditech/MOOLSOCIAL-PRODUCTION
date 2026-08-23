# MVP Git, Flutter and OPPO action/workspace reconciliation

Date: 5 August 2026
State: verified read-only audit; planning decision recorded; no successor active

## Exact identity verified

- Branch: `remediation/prototype-conformance-2026-07-20`
- Local HEAD: `f6dfe7587aa02d782e94282d14af8bafff48ded0`
- Local remote-tracking HEAD: `f6dfe7587aa02d782e94282d14af8bafff48ded0`
- Direct Git remote branch result:
  `f6dfe7587aa02d782e94282d14af8bafff48ded0`
- Sealed Flutter/app-test source: 2,466 files, SHA-256
  `A05B47F0893778064E255574DF3678BF198DAE72A18DA7C81710693557AE1BEE`
- Connected OPPO: CPH2375, serial `2b3e0f71`
- Installed package: `com.moolsocial.app`
- Installed profile: `1.0.0-r58.23 (2026080419)`
- On-device `base.apk` SHA-256:
  `F0C1061D1D7897130528533F254B41BDC48FE7958E7DD9B50624FEF6EE3B5DC9`
- Device animation scales: `1/1/1`

`scripts/verify-moolsocial-resume-checkpoint.ps1` passed after the planning
records were written. Git LFS, the complete sealed source manifest and approved
APK bytes remain exact.

## What the exact installed APK currently exposes

The OPPO replay confirmed the pre-directive Flutter surface:

| Main action | Installed OPPO sub-actions |
| --- | --- |
| Social | Shorts, Videos, Feed, Create |
| Buy | Shop, Wholesale, Medicine, Orders |
| Eat | Order Food, Book Table, Tiffin |
| Ride | Bike, Auto, Cab |
| Book | Get It Done, Doctor, Salon |
| Pay | Recharge, Bills, Scan & Pay, Receipts |
| Work | Earn Today, Delivery, Onboard, Verify, Workspace |
| Chat | Global bottom action with unread state |

This proves that the exact founder action refinement is not yet implemented in
the protected APK. Tiffin, Get It Done, standalone Pay, and universal Work
Delivery/Onboard/Verify are still visible. They require a new reference/runtime
candidate; planning memory cannot change the installed UI.

The OPPO remained on the exact installed build. No app install, app-data clear,
account mutation, payment, provider/backend action or external-service write
was performed.

## After-login workspace reality

The current installed journey is structurally useful:

`personal account remains active -> Start My Work -> Earn with MoolSocial OR
Grow my business -> choose family -> choose profile -> setup`

The OPPO showed:

- **Earn with MoolSocial** — `Freelancer, delivery, captain or service work`;
- **Grow my business** — `Shop, food, health, salon, transport or supply`;
- family choices including Products & Trade, Food Business, Health & Medicine,
  Services & Salon and Ride & Transport; and
- Products & Trade choices: Grocery / Kirana Shop, Speciality Retail Shop,
  Wholesaler / Distributor and Manufacturer / Supplier.

The source confirms additional broad combined choices such as Clinic / Doctor,
Cloud Kitchen / Tiffin, Salon / Wellness, Local Service Provider, Ride /
Delivery Captain, Creator and Freelancer / Job Seeker.

The current screen says `Only profiles with a complete setup path are shown`.
That is not yet a truthful Production statement because these routes still use
review/local owners and several types are postponed, dependency-held or
combined more broadly than the exact Admin registry.

## Founder-aligned workable workspace decision

Keep the two-step narrowing because it prevents a normal user from seeing a
29-item role wall and preserves one personal account. Correct its contents and
authority as follows.

### Step 1 — normal user

After sign-in, the user remains a Personal user and reaches the normal
MoolSocial customer surface. No mandatory role question blocks first use.

### Step 2 — intentional workspace entry

Profile/Work -> **Workspace** offers only:

1. **Earn with MoolSocial**; and
2. **Run a business or professional workspace**.

If the account already has an active workspace, reopen it first and place
**Add another workspace** behind a separate explicit action.

### Step 3 — Admin-controlled launch families

Show only a family that contains at least one currently registered, enabled and
complete exact setup path for the user's geography and account eligibility.
The family is navigation, not permission.

- Earn: Freelancer / Field Partner, Delivery Partner, Bike Captain, Auto
  Captain, Cab / Car Captain and an eligible creator workspace after the
  YouTube/Social dependency.
- Products & Trade: Grocery / Kirana Shop, enabled General Retail Shop /
  Dukaan, FMCG Supplier / Distributor and a separately enabled bounded FMCG
  Manufacturer pilot.
- Food & Tables: Restaurant / Dhaba / Cafe only for Order Food and Book Table.
- Health & Medicine: Individual Doctor and Medical Store / Pharmacy as two
  separate permissions.
- Salon: Salon / Parlour only.

The selection cannot contain `Ride / Delivery Captain`, `Manufacturer /
Supplier`, `Clinic / Doctor`, generic `Creator`, generic `Local Service
Provider` or another combined actor. Future registered-disabled profiles remain
in Admin product memory but are not presented as usable setup paths.

### Step 4 — exact preview before creation

Before **Create workspace**, show exact benefits, subscription or transaction
charges, verification/licence/document requirements, geography, allowed
capabilities, excluded capabilities and what becomes available after approval.
Creation produces a server-owned pending workspace; it never grants capability
locally.

## Pending ticket-family map

These are parent families, not executable authorization. Each new family must
later be expanded into exact actor/capability child tickets and presented for
the founder's requested batch preauthorization.

| Priority | Parent ticket family | Current state | Required outcome |
| ---: | --- | --- | --- |
| 0 | YouTube compliance sequencing | Active dependency; reply remains unsent unless separately authorized | Resolve the current reviewer-access question and record the provider result before final Social activation. |
| 1 | `MVP-UNIVERSAL-ACTION-EXPOSURE-AND-WORKSPACE-ROUTING` | New batch required | Freeze a new HTML reference and native contract that removes postponed customer promises and makes Work expose only Earn Today and Workspace. |
| 2 | `MVP-EXACT-WORKSPACE-REGISTRY-ADMIN-ACTIVATION-AND-CREATION` | New batch required | Admin registers/enables exact types; customer sees progressive families; workspace creation is pending/authoritative; disabled or incomplete types cannot appear usable. |
| 3 | `BUY-MVP-READY-ORDER-TO-DELIVERY-END-TO-END-JOURNEY` | Existing 47-child portfolio preauthorized, not executing | Complete Shop, Wholesale and Medicine using the exact provider bindings in the founder action directive. |
| 4 | `RIDE-MVP-FARE-TO-SAFE-COMPLETED-TRIP-END-TO-END-JOURNEY` | New 30–50-child batch required | Complete Bike, Auto and Cab customer, exact Captain, dispatch, safety, payment, support and Admin journeys. |
| 5 | `EAT-MVP-READY-ORDER-AND-TABLE-TO-COMPLETION-END-TO-END-JOURNEY` | New 30–50-child batch required | Complete Restaurant / Dhaba / Cafe Order Food and Book Table without adding Tiffin or Cloud Kitchen. |
| 6 | `BOOK-MVP-DOCTOR-AND-SALON-TO-SERVED-END-TO-END-JOURNEY` | New 30–50-child batch required | Complete Individual Doctor and Salon / Parlour decision, booking, provider acceptance, payment, served proof and recovery; no Get It Done. |
| 7 | `WORK-MVP-FUNDED-OPPORTUNITY-TO-AUDITABLE-PAYOUT-END-TO-END-JOURNEY` | Existing 45-child portfolio preauthorized, not executing | Keep universal Earn Today/Workspace and move onboarding, verification, delivery and proof into the exact workspace. |
| 8 | `CHAT-MVP-GLOBAL-INDIVIDUAL-SHARED-AND-JOURNEY-CONTINUITY` | New batch required | Deliver real-time direct/shared conversations, attachments, unread/sync, block/report, business-action context and offline recovery without copying WhatsApp UI. |
| 9 | `PAYMENT-MVP-SHARED-TRANSACTION-INTEGRITY` | Existing payment foundations must be reconciled into one bounded batch | Provide embedded order/booking/trip/work payment intents, provider callback truth, idempotency, reconciliation, refunds and receipts; no standalone Pay main action. |
| 10 | `SOCIAL-MVP-CONTENT-TO-DECLARED-ACTION-END-TO-END-JOURNEY` | Existing 42-child portfolio proposed and dependency-held | Finalize Shorts/Videos after YouTube; keep native text/carousel Feed; connect only accepted Buy or Work actions. |
| 11 | `SUPERADMIN-MVP-EXACT-LAUNCH-PARTICIPANT-PROVISIONING-AND-CONTROL-END-TO-END-JOURNEY` | Planning candidate, not registered | Control exact profile/capability/geography/status, reviewer decisions, timers, health, pause and rollback. |
| 12 | `MVP-CUMULATIVE-CROSS-ACTION-RELEASE-QUALIFICATION` | Terminal family required after applicable verticals | Two full regressions, exact-source build, OPPO consumer/provider/admin replay, accessibility, lifecycle, performance, safety, payment and founder acceptance. |

## Recommended next bounded planning ticket

The next independent ticket to write in full is:

`MVP-UNIVERSAL-ACTION-EXPOSURE-AND-WORKSPACE-ROUTING-REFERENCE-BATCH`

Classification: `mvp_required`.

Ticket-making completed after the audit:
`docs/delivery/MVP-UNIVERSAL-ACTION-EXPOSURE-AND-WORKSPACE-ROUTING-REFERENCE-BATCH-TICKET-20260805.md`.
Its 45-child machine manifest is
`config/mvp-universal-action-workspace-routing-reference-batch.json` at
SHA-256
`45D765390EA6B2D94F334CB4F5B2AB67162657A447B220A10650EB7621DB34A8`.
It is registered for founder review only, not preauthorized or executing.

Reason: the exact installed APK currently promises postponed journeys and uses
broad combined workspace choices. Correct exposure and authoritative workspace
routing are prerequisites for every vertical and prevent users from entering a
convincing but non-live review journey.

Minimum complete scope: new founder-reviewed HTML action/workspace states,
exact capability registry reads, truthful held/disabled/loading/offline/denied
states, progressive two-step workspace selection, route preservation, native
Flutter parity and regression/OPPO evidence.

Explicit exclusions: no vertical backend implementation, subscription charge,
provider activation, YouTube enablement, payment movement, migration of an
existing workspace, build or OPPO install until the exact ticket is separately
disclosed and authorized.
