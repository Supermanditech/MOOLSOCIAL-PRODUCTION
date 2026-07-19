# MoolSocial production development cascade

Date: 20 July 2026  
Target: controlled Android and iOS launch by 1 September 2026  
Clients: shared Flutter mobile app, Next.js business/admin web  
Backend direction: managed Google/Firebase services with thin Cloud Run
services only where transactional rules or third-party integrations require
them

## Delivery rule

Development does not proceed as “all frontend, then all backend.” Every ticket
is completed as one observable vertical outcome:

`contract → UI → generated client/API → authoritative data → cloud deploy →
clean-state runtime test → exact failure replay → affected journey regression
→ staging promotion`

A ticket is not complete when a screen renders or a local review gateway
returns success. Completion requires:

1. dev and staging environments remain isolated;
2. the authoritative server owns money, stock, eligibility and status changes;
3. retry is idempotent and cannot create a duplicate charge, order, payout or
   message;
4. offline, denied, expired, invalid, cancelled and provider-failure results are
   explicit;
5. observability records the action and outcome without private message,
   document, OTP or payment content;
6. Android and iOS consume the same versioned contract;
7. the original failed user sequence and the full affected journey pass on
   staging.

## Cascade overview

| Layer | Outcome | Entry condition | Exit condition |
| ---: | --- | --- | --- |
| 0 | Release foundation | repository is green | dev/staging/prod, CI and signed distribution paths exist |
| 1 | Identity and account | Layer 0 dev environment | one real user can install, sign in and reach Universal |
| 2 | Shared platform capabilities | authenticated account | consent, files, chat, notifications and search contracts work |
| 3 | Money and audit | identity, App Check and command envelope | one idempotent payment reconciles to one ledger result |
| 4 | Consumer commerce and fulfilment | money and shared contracts | consumer order completes through retailer and delivery |
| 5 | Bookings and dispatch | geo, notification and money contracts | ride/service booking completes with authoritative status |
| 6 | Social, Creator and funded work | files, moderation, money and identity | connected content or funded work completes its declared result |
| 7 | Business workspaces | commerce/work foundations | retailer, manufacturer, captain and provider operate live records |
| 8 | Superadmin and controlled launch | every command is authoritative | governed rollout, support, finance and rollback pass |

## Layer 0 — release foundation

### PROD-FDN-001 — create isolated Google/Firebase environments

- Source progress: complete — mobile configuration now fails closed outside
  debug, and Auth/Data Connect emulator routing is compile-time isolated.
- External progress: blocked — live dev, staging and production project
  provisioning awaits resolution of the Google billing account.
- Scope: `moolsocial-dev`, `moolsocial-staging`, `moolsocial-production`.
- Automate: Firebase app registration, Data Connect connector generation,
  Secret Manager references, App Check, Remote Config, FCM, Crashlytics,
  Performance Monitoring, budget alerts and least-privilege service accounts.
- Never commit: production Firebase configuration files, OAuth secrets,
  signing keys or payment credentials.
- Blocker: the `hello@moolsocial.com` Google Cloud billing/project issue must be
  resolved by Google. Local implementation continues against emulators.
- Accept: each client build is permanently tied to one environment and cannot
  switch environments at runtime.

### PROD-FDN-002 — continuous integration and immutable artifacts

- Source progress: copy, interaction, Flutter, Android, hosted iOS and
  Superadmin desktop/mobile gates are now declared in GitHub Actions.
- Run copy, interaction, format, analyzer, unit, widget, golden, contract and
  browser tests on every accepted change.
- Build Android APK/AAB on Linux and iOS simulator on hosted macOS from the same
  commit.
- Promote the same tested artifact through internal, closed and staged release;
  never rebuild source differently for production.
- Accept: failed gates prevent promotion and every artifact records commit,
  contract version and environment.

### PROD-FDN-003 — store signing and release identity

- Preserve Android and iOS identifier `com.moolsocial.app`.
- Configure Play App Signing, protected Android upload key, App Store Connect,
  TestFlight and CI-held signing credentials.
- Accept: one tagged commit produces installable Android and iOS staging
  artifacts without developer-machine secrets.

### PROD-FDN-004 — feature flags, rollback and budget guardrails

- Define kill switches by journey, app version, user type, geography and
  external provider.
- Add daily budget alerts for Cloud Run, Cloud SQL/Data Connect, Firestore,
  Storage/CDN, maps, OTP, notifications and media.
- Accept: a failing feature can be stopped without blocking sign-in, account
  recovery or unrelated orders.

### PROD-FDN-005 — migrate plugins to Flutter built-in Kotlin support

- Discovery: the current Android debug build succeeds, but Flutter warns that
  seven plugins still apply the Kotlin Gradle Plugin and a future Flutter
  version will reject that build path.
- Upgrade or replace `desktop_webview_auth`, Firebase Analytics, App Check,
  Performance, Remote Config, `mobile_scanner` and `speech_to_text` with
  versions that support Flutter's built-in Kotlin integration.
- Re-run Android debug/release, permission denial, scan, voice, social sign-in
  fallback and Firebase initialization on the minimum supported Android API.
- Accept: Android debug and release builds complete without the deprecated-KGP
  warning and all affected journeys pass.

## Layer 1 — identity and account

### PROD-ID-001 — production Firebase Authentication

- Source progress: environment-injected Firebase Auth wiring is implemented;
  live staging verification remains pending.
- Configure Indian phone OTP, abuse limits, Play Integrity/App Attest, Google
  and Apple identity providers, account linking and safe sign-out.
- Never display a fixed OTP or log an OTP.
- Accept: install → setup → sign-in → retry/expiry/invalid code → successful
  account session passes on staging Android and iOS.
- Depends on: `PROD-FDN-001`, `PROD-FDN-003`.

### PROD-ID-002 — idempotent account bootstrap

- Use Firebase Data Connect generated SDK for account, personal profile,
  language, area, consent receipt and active-workspace pointers.
- Make bootstrap retry-safe after network loss or app termination.
- Accept: one Firebase identity creates or resumes exactly one MoolSocial
  account and opens the requested return destination.
- Depends on: `PROD-ID-001`.

### PROD-ID-003 — authorization and App Check command envelope

- Every write carries authenticated account, role/workspace claim, App Check,
  idempotency key, client contract version and audit reference.
- Enforce workspace RBAC server-side; UI visibility is never authorization.
- Accept: missing, expired, cross-workspace and replayed commands are denied
  without mutating state.
- Depends on: `PROD-ID-002`.

## Layer 2 — shared platform capabilities

### PROD-PLT-001 — identity, consent and account controls

- Implement screens 157–162 and 165 against authoritative account, consent,
  session, device and notification preference services.
- Record versioned consent receipts and revocation effects.
- Accept: every control previews its effect, confirms sensitive changes and
  remains retry-safe.
- Depends on: `PROD-ID-003`.

### PROD-PLT-002 — private files and evidence

- Use signed uploads to Cloud Storage, server-side type/size/virus checks,
  purpose-bound metadata, retention and owner-scoped download URLs.
- Accept: invalid, cancelled, permission-denied, offline and duplicate uploads
  never create an exposed or orphaned record.
- Depends on: `PROD-ID-003`.

### PROD-PLT-003 — chat, realtime state and notifications

- Source progress: Universal People, Business, Orders and Support now route
  directly to filtered production inbox states; every thread has persistent
  Mool access. Linked catalogue, quote, basket, payment, order-support, media,
  poll, invite, detail and update intents now have direct owners; empty and
  duplicate drafts, failure, retry, protected return, compact and four approved
  visual states pass locally and on the connected OPPO.
- Use Firestore realtime conversation state, Cloud Storage attachments and FCM
  fan-out behind a versioned messaging API.
- Separate people, business, order and support permissions.
- Accept: offline send remains visible, exact retry delivers once, return
  navigation is preserved and blocked users cannot receive new content.
- Depends on: `PROD-ID-003`, `PROD-PLT-002`.

### PROD-PLT-004 — search, area and discovery

- Start with Data Connect/PostgreSQL indexed catalogue and service queries;
  add a separate search service only after measured need.
- Store geospatial service areas and eligibility rules server-side.
- Accept: search returns only eligible, available, permitted results with an
  empty-state recovery and no consumer wholesale leakage.
- Depends on: `PROD-ID-003`.

## Layer 3 — money and audit

### PROD-MNY-001 — payment provider command and webhook inbox

- Integrate the selected Indian PSP behind `PaymentGateway`.
- Server creates payment intent; signed webhooks are stored once before
  processing; client return is never treated as final payment proof.
- Accept: success, pending, failed-no-debit, delayed webhook, duplicate webhook,
  abandoned return, refund and reversal each settle to one authoritative
  result.
- Depends on: `PROD-ID-003`.

### PROD-MNY-002 — double-entry ledger and protected balances

- Implement immutable ledger entries for customer payment, platform fee,
  merchant payable, worker/creator payable, refund, reversal and adjustment.
- Balance is derived from posted entries; it is never a mutable client field.
- Accept: every receipt, payable and reconciliation line traces to balanced
  entries and one business reference.
- Depends on: `PROD-MNY-001`.

### PROD-MNY-003 — payouts, settlements and reconciliation

- Implement merchant, captain, worker and creator settlement schedules,
  identity gates, failed transfer recovery and bank/PSP reconciliation.
- Accept: a payout is shown as paid only after provider confirmation and
  duplicate payout commands return the original result.
- Depends on: `PROD-MNY-002`.

## Layer 4 — consumer commerce and fulfilment

### PROD-COM-001 — catalogue, price and inventory reservation

- Data Connect owns products, sellers, household packs, price, tax, service
  area, stock and reservation expiry.
- Consumer Buy excludes wholesale MOQ, trade campaigns and demand aggregation.
- Accept: product decision shows final pack, seller, price, delivery promise
  and refund rule; unavailable stock cannot enter checkout.
- Depends on: `PROD-PLT-004`.

### PROD-COM-002 — idempotent basket and order

- Persist basket, home delivery/store collection, substitution rule, address,
  quote and order command.
- Reserve stock and price before payment; one idempotency key creates one
  order.
- Accept: duplicate Add increments one line, failed payment creates no order,
  retry preserves the basket and creates exactly one paid order.
- Depends on: `PROD-COM-001`, `PROD-MNY-001`.

### PROD-COM-003 — food, table and tiffin contracts

- Implement menu availability, kitchen capacity, customization, table hold,
  deposit, subscription schedule, skip/pause and cancellation.
- Accept: order/table/tiffin remain separate authoritative contracts while
  sharing identity, payment and support.
- Depends on: `PROD-MNY-001`, `PROD-PLT-004`.

### PROD-COM-004 — issue, refund, replacement and support linkage

- Link issue type, selected items, evidence, merchant response, policy decision
  and money result to the original transaction.
- Accept: support never asks the user to reconstruct data already attached to
  the order and no refund is claimed before ledger confirmation.
- Depends on: `PROD-COM-002`, `PROD-PLT-002`, `PROD-MNY-002`.

### PROD-COM-005 — regulated Medicine and pharmacy requests

- Source progress: dedicated Medicine UI, direct Universal/search routes,
  prescription and pharmacist failure/retry contracts, idempotent review
  gateways, compact accessibility checks and three golden states are complete.
- Implement jurisdiction-aware medicine catalogue and licensed-seller
  eligibility; never mix regulated Medicine inventory into the general
  household catalogue.
- Store prescriptions through private-file controls, expose purpose-bound
  access, retention and audit, and prevent raw prescription content from logs.
- The server must own prescription acceptance, medicine availability, final
  price and the transition to payment. A client tap cannot claim acceptance or
  debit.
- Link pharmacist requests to Chat with one request reference and explicit
  response/status ownership.
- Accept: eligible non-prescription item reaches Basket; prescription and
  pharmacist invalid/failure/retry/duplicate flows preserve one authoritative
  result; no charge occurs before licensed acceptance.
- Depends on: `PROD-COM-001`, `PROD-COM-002`, `PROD-PLT-002`,
  `PROD-PLT-003`, `PROD-MNY-001`.

### PROD-OPS-001 — retailer fulfilment and delivery handover

- Implement accept/cannot-fulfil, pick/pack, delivery request, captain match,
  one-time handover code, tracking, customer delivery proof and receipt.
- The retailer never sees a hard-coded handover OTP.
- Accept: one paid consumer order completes to one delivery and Business Book
  entry; every rejected or expired step leaves stock and money consistent.
- Depends on: `PROD-COM-002`, `PROD-PLT-003`.

## Layer 5 — booking and dispatch

### PROD-OPS-002 — ride/captain dispatch

- Integrate maps/geocoding, eligible supply, fare quote, captain offer,
  pickup-code verification, live trip, safety and final fare.
- Accept: customer and captain observe one trip state; final payment requires
  customer approval and provider confirmation.
- Depends on: `PROD-MNY-001`, `PROD-PLT-003`, `PROD-EXT-001`.

### PROD-OPS-003 — doctor, salon, task and service-provider booking

- Source progress: Doctor clinic contact, patient QR, consent-bound invite
  link, one-time reception code, prescription QR and follow-up slot actions now
  have visible owners. Repeated code and prescription actions remain
  duplicate-safe, and the full nested sequence passes on the connected OPPO.
- Implement provider catalogue, availability, slot/hold, patient consent,
  arrival/proof, protected release and support.
- Separate health information from ordinary commerce and apply least-privilege
  consent.
- Accept: invalid capacity cannot be booked; cancellation/payment/proof rules
  remain visible and authoritative.
- Depends on: `PROD-MNY-001`, `PROD-PLT-001`, `PROD-PLT-003`.

### PROD-EXT-001 — external location, calling and safety adapters

- Wrap maps, navigation, masked calling and emergency escalation behind
  explicit interfaces and provider health checks.
- Accept: an unavailable external provider produces a safe recovery, never a
  false completion.
- Depends on: `PROD-FDN-004`.

## Layer 6 — Social, Creator and funded work

### PROD-SOC-001 — YouTube Connect

- Implement Google OAuth with minimum YouTube scopes, channel/video selection,
  token encryption/revocation, ownership checks and linked-content refresh.
- MoolSocial stores the connection, context, disclosure and action—not a copy
  of the YouTube video.
- Accept: revoked, private, deleted, age-restricted and unavailable videos show
  an explicit recovery.
- Depends on: `PROD-ID-003`.

### PROD-SOC-002 — business-funded 1–7 day Reels

- Source progress: the Creator review experience now exposes every funded
  duration from 1 through 7 days without hidden horizontal choices, states
  automatic expiry, and passes compact 140% text regression. Live campaign,
  media, moderation and ledger services remain pending.
- Allow only funded campaigns with explicit 1, 2, 3, 4, 5, 6 or 7-day duration
  (24–168 hours), maximum exposure, rights declaration and stop condition.
- Use a managed media provider behind `MediaGateway`; retain only for the
  contracted campaign/evidence period.
- Accept: upload/transcode/moderation failure cannot consume budget or publish;
  expiry removes discovery while preserving auditable campaign proof.
- Depends on: `PROD-PLT-002`, `PROD-MNY-002`, `PROD-SOC-003`.

### PROD-SOC-003 — social graph, feed, rights and moderation

- Implement follows, feed/posts, save/share/remix permissions, disclosure,
  report/block, moderation queue and action attribution.
- Every visible card/rail action must complete or expose the next required
  decision.
- Accept: Shorts, Videos, Feed and Create pass success, empty, cancelled,
  denied, retry and moderation outcomes.
- Depends on: `PROD-ID-003`, `PROD-PLT-003`.

### PROD-SOC-004 — audience, campaign and attribution

- Resolve eligible audiences without exporting raw user lists.
- Attribute product/service/work outcomes using signed server events and
  consent-aware aggregate reporting.
- Accept: campaign spend, reach and outcome cannot be self-reported by a client
  or creator.
- Depends on: `PROD-SOC-003`, `PROD-COM-002`, `PROD-MNY-002`.

### PROD-WRK-001 — funded opportunities and eligibility

- Implement funded budget, exact output, eligibility, capacity, expiry,
  application and terms acceptance.
- Accept: unfunded work is never published; duplicate apply returns the
  original application.
- Depends on: `PROD-ID-003`, `PROD-MNY-002`.

### PROD-WRK-002 — user-type workspace onboarding

- Implement personal plus approved workspace profile choice, proofs, GST when
  applicable, verification, rejection/correction and activation.
- Accept: personal consumer/social access remains active while workspace
  verification is pending or rejected.
- Depends on: `PROD-ID-002`, `PROD-PLT-002`.

### PROD-WRK-003 — retailer live workspace

- Connect verified retailer identity to catalogue, stock, orders, delivery,
  books, staff permissions and settings.
- Accept: workspace role and store scope are enforced server-side.
- Depends on: `PROD-WRK-002`, `PROD-COM-001`.

### PROD-WRK-004 — result-based offerings

- Superadmin can provision a product, service, campaign or funded result to one
  or more eligible user types with price/budget, capacity, geography, terms,
  approval and rollback.
- Accept: the same versioned offering contract renders role-specific UI in
  mobile/business web and cannot exceed approved exposure.
- Depends on: `PROD-ADM-002`, `PROD-MNY-002`.

### PROD-WRK-005 — proof, review, appeal and payout

- Implement required proof schema, signed upload, reviewer separation,
  correction, rejection reason, appeal and payout release.
- Accept: payout cannot release before required proof and approval; duplicate
  submission does not create a second outcome.
- Depends on: `PROD-WRK-001`, `PROD-PLT-002`, `PROD-MNY-003`.

## Layer 7 — business workspaces

### PROD-RTL-001 — retailer POS sale and invoice

- Implement counter, line items, price/tax, payment, invoice and atomic stock
  movement.
- Accept: one completed sale creates one invoice, payment result and stock
  movement; offline replay cannot duplicate them.
- Depends on: `PROD-WRK-003`, `PROD-MNY-001`.

### PROD-RTL-002 — POS offline queue and conflict recovery

- Store encrypted pending commands, synchronize in order and expose conflicts
  for owner action.
- Accept: reconnect replays each command once and never overwrites newer stock
  silently.
- Depends on: `PROD-RTL-001`.

### PROD-RTL-003 — wholesale procurement

- Implement eligible supplier catalogue, case/MOQ pricing, purchase order,
  dispatch, goods receipt, variance, supplier bill and payment.
- Accept: wholesale data appears only inside eligible business workspaces.
- Depends on: `PROD-WRK-003`, `PROD-MNY-001`.

### PROD-RTL-004 — Business Book projections and export

- Derive sales, purchases, stock, cash/bank, expenses, tax evidence and
  reconciliation from authoritative records.
- Accept: exports are permission-checked, auditable and match screen totals.
- Depends on: `PROD-RTL-001`, `PROD-RTL-003`, `PROD-MNY-002`.

### PROD-RTL-005 — recovery, staff, settings and issues

- Implement stock recovery actions, store readiness, scoped staff RBAC,
  licences and customer issue control.
- Accept: staff cannot see money or perform owner commands without the required
  permission.
- Depends on: `PROD-WRK-003`, `PROD-COM-004`.

### PROD-AI-001 — policy-bound operating assistant

- AI proposes actions from authorized workspace data; it cannot move money,
  publish, message, change stock or accept work without explicit owner review
  and deterministic command validation.
- Accept: prompt injection, missing permission and unsafe output tests cannot
  bypass the same APIs used by the human UI.
- Depends on: `PROD-ID-003`, `PROD-RTL-005`.

### PROD-MFG-001 — manufacturer catalogue, sales and dispatch

- Implement trade products, territories, buyer eligibility, order terms,
  advance, production/dispatch and delivery evidence.
- Accept: confirmed quantity, price, date, advance and claim rules are visible
  before commitment.
- Depends on: `PROD-MNY-001`, `PROD-WRK-002`.

### PROD-MFG-002 — manufacturer procurement, demand and claims

- Implement input procurement, demand targets, funded campaigns, claims, team
  roles and business services.
- Accept: campaign and target reporting uses authoritative attributed outcomes.
- Depends on: `PROD-MFG-001`, `PROD-SOC-004`.

## Layer 8 — Superadmin and launch

### PROD-ADM-001 — production Superadmin authentication and RBAC

- Replace review-mode access with Firebase session verification, server-side
  admin role claims, step-up authentication and audited access expiry.
- Accept: default access is denied; no client environment switch can grant an
  admin role.
- Depends on: `PROD-ID-003`.

### PROD-ADM-002 — governed offering and command APIs

- Implement draft, validation, independent approvals, canary, expansion,
  pause, stop and rollback for profile-specific offerings and operational
  commands.
- Accept: every protected command previews scope, requires confirmation where
  material and is idempotent.
- Depends on: `PROD-ADM-001`, `PROD-FDN-004`.

### PROD-ADM-003 — support, finance, health and privacy-safe audit

- Implement masked case timelines, product health, reconciliation, dispute,
  moderation and consent controls without exposing private content.
- Accept: emergency control can stop one class while core unrelated journeys
  remain available.
- Depends on: `PROD-ADM-001`, `PROD-MNY-003`.

### PROD-REL-001 — staging black-box and device matrix

- Run all screen/tap/nested-tap tests from clean state on staging.
- Run Android physical devices/Test Lab and iOS simulator/TestFlight matrix,
  large text, reduced motion, permission denied, offline and process restart.
- Accept: exact failed sequences, affected journeys and full regression pass
  against staging services.
- Depends on: all launch-scope tickets.

### PROD-REL-002 — backup, restore, incident and rollback drill

- Verify database backup/point-in-time recovery, storage retention, key
  rotation, provider outage, feature rollback and customer support runbooks.
- Accept: restore and rollback meet written recovery targets with evidence.
- Depends on: `PROD-REL-001`.

### PROD-REL-003 — controlled release

- Release internal → closed → percentage rollout with crash-free, latency,
  payment, order and intent-completion gates.
- A human owner approves store production release.
- Accept: evidence-based GO has no open launch-blocking intent path.
- Depends on: `PROD-REL-002`.

## First production vertical slice

The first implementation sequence remains:

1. `PROD-FDN-001` through `PROD-FDN-005`;
2. `PROD-ID-001` through `PROD-ID-003`;
3. screens 00–04 on real staging;
4. `PROD-COM-001`, `PROD-COM-002`, `PROD-MNY-001`;
5. screens 09–18 plus retailer screens 74–77;
6. `PROD-COM-005` when the jurisdiction, licensed-pharmacy and private-file
   controls are approved;
7. only then add the next end-to-end launch journey.

This sequence gives visible production outcomes early and prevents a large
unintegrated frontend/backend merge at the end of the schedule.
