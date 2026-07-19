# QA-016 — Retailer stock recovery, assisted actions and controls

Date: 19 July 2026

## Scope

- Approved HTML behavior source: screens 101–105
- Slow-stock recovery using only available, safe and undisputed stock
- Customer offer, retailer transfer, bundle and supplier-claim routes
- Approval-gated, workspace-grounded Mool AI explanations and drafts
- Least-privilege staff invitations, access changes, devices and history
- Shop readiness, profile, hours, fulfilment, payments, invoices, returns,
  staff, compliance and versioned save
- Customer-issue evidence, message, replacement, refund and evidence-request
  outcomes
- Invalid, empty, duplicate, cancelled, loading, retry, offline,
  unauthorized and gateway-failure outcomes

## Screen-by-screen tap and nested-tap coverage

| Approved screen | Production intent path | Covered controls and nested outcomes |
|---:|---|---|
| 101 | Move one slow product without exposing protected stock | Back; Stock Statement; all three stock products; excluded reserved, disputed and unsafe stock; Customer offer, Retailer transfer, Build bundle and Supplier claim; valid and excessive quantity; positive and zero price floor; 2, 4 and 7 day duration; Review; Publish; gateway failure; exact retry; duplicate publish; offline |
| 102 | Understand shop data and prepare an owner-approved action | Back; history; free prompt; Restock, Slow, Dues, Offer and Profit prompts; failed answer; exact retry; answer evidence; purchase review; purchase dismiss; offer review; offer dismiss; no autonomous mutation; offline; role denial |
| 103 | Give staff only the access needed for their role | Back; Add staff; close invite; name; mobile; Owner, Manager, Billing and Packing roles; invalid mobile; failed invite; exact retry; duplicate invite; all staff rows; manage cancellation; pause/resume failure; exact retry; devices; activity history; offline; role denial |
| 104 | Keep the shop ready for customer orders | Back; Save; readiness reminder; profile; hours; Accept app orders; Store collection; Home delivery; UPI, cash and card; invoices; returns and issues; staff access; GST; licence; Business Services; every edit sheet; failed save; exact retry; duplicate version; offline; role denial |
| 105 | Resolve one customer issue against evidence and protected payment | Back; support chat; Confirm outcome; All, Open, Refund, Delivery and Quality filters; every case; Replacement, Refund and Request evidence; invalid short message; customer message; receipt; evidence; failed resolution; exact retry; duplicate resolution; offline; role denial |

## Locked control rules

- Recovery uses sellable stock only. Reserved, disputed, recalled or unsafe
  units cannot be selected.
- Recovery quantity cannot exceed the selected product’s eligible units.
- The retailer reviews a recovery route before it is published.
- Mool AI may explain records and prepare drafts, but it cannot purchase,
  publish, refund or change business data without explicit approval.
- AI answers are limited to records the signed-in role is authorized to read.
- Staff permissions are role based and least privilege; an invite creates no
  access until accepted.
- Pausing staff access is a protected, idempotent command with history.
- Shop settings save as one versioned outcome so partial toggles are not
  represented as committed server state.
- Issue resolution is tied to the selected case, evidence, retailer message
  and one explicit outcome.
- Duplicate commands never publish a second recovery, send a second invite,
  save a second settings version or resolve an issue twice.

## Defects discovered and exact failed-tap replays

| Ticket | Defect and root cause | Fix | Exact original replay |
|---|---|---|---|
| CT-001 | The staff-role dropdown overflowed on a compact device because its selected label could not share the fixed row width | Made the dropdown use its available width with `isExpanded: true` | Screen 103 → Add staff → open/change role at 412 px: every role renders and the invite remains tappable |
| CT-002 | Clearing an empty retailer-home search restored data but not the scroll position after new control cards increased the lazy list extent | Added a home-list scroll controller and return-to-top behavior after search recovery | Screen 74 → search unmatched text → Clear search: live orders and first actions are visible again |
| CT-003 | The first AI trust card put explanatory copy and its approval badge in competing horizontal regions, creating unnecessary height | Rebuilt it as one grounded-data row and one compact approval boundary row | Screen 102 clean entry at 412 × 915: trust source, draft-only status and owner approval rule are all visible above the prompt |
| CT-004 | The settings-readiness card used one long descriptive block and obscured the single action needing attention | Split readiness proof from a dedicated licence-reminder action row | Screen 104 clean entry at 412 × 915: readiness and the actionable reminder are independently scannable and tappable |

## Exact failed-operation replays

- Quantity above eligible slow stock and a zero price floor are rejected before
  publish.
- Recovery publish failure commits no action; the exact retry publishes
  `REC-101-0715` once; duplicate submit creates no second recovery.
- AI gateway failure returns no fabricated answer; the exact prompt retry
  succeeds, while no shop mutation occurs.
- Invalid staff mobile calls no gateway. Invite failure creates no access; the
  exact retry sends `INV-103-0715` once; duplicate submit sends nothing again.
- Staff access-change cancellation preserves access. Gateway failure also
  preserves access; exact retry applies one audited change.
- Settings save failure creates no committed version; exact retry creates
  `SET-104-0715`; duplicate save creates no second version.
- An issue message shorter than 12 characters calls no gateway. Resolution
  failure changes neither payment nor case; exact retry creates
  `RES-105-0715`; duplicate confirm creates no second outcome.
- Offline and unauthorized commands call no protected gateway and preserve
  every recovery, AI, staff, settings and issue outcome.

## Independent UI/UX enhancement cycle

The enhancement cycle began only after the first dedicated, affected and full
regression passes were clean.

- Added and inspected stable 412 × 915 baselines for all five screens.
- Kept decisive metrics and the next useful action in the first viewport.
- Made the AI source, authorization and owner-approval boundary explicit.
- Made shop readiness and its one current compliance action independently
  tappable.
- Preserved the Apple-inspired rounded surfaces, restrained color hierarchy,
  compact action rows and persistent Mool outcome dock.
- Preserved every production route, key, validation, authorization and
  idempotency boundary during the enhancement.

## Test and replay results

Before the independent UI/UX enhancement:

- Dedicated screen 101–105 black-box scenarios: 9/9 passed.
- Affected retailer journeys: 62/62 passed.
- Full application regression pass 1: 185/185 passed.
- Flutter analyzer: no issues.

After the independent UI/UX enhancement:

- Dedicated screen 101–105 black-box scenarios: 9/9 passed.
- New screen 101–105 visual baselines: 5/5 passed twice.
- Affected retailer functional and visual regression: 67/67 passed.
- Full application regression pass 2: 190/190 passed.
- Flutter analyzer: no issues.
- Enhanced physical OPPO CPH2375 replay: 1/1 passed twice, including a
  `flutter clean`, dependency restore, fresh APK build and fresh install for
  the second cycle.

## Physical OPPO evidence

- Device: OPPO CPH2375, device ID `2b3e0f71`.
- Package: `com.moolsocial.app`.
- Exact replay: Slow Stock → Juice → Customer offer → Review → Publish →
  Mool AI slow-stock prompt → Answer → Store Settings → toggle orders → Save →
  Staff Access → Add → Invite → Customer Issues → Refund → Confirm.
- Assertions: one `REC-101-0715`, grounded answer, one `SET-104-0715`, one
  `INV-103-0715`, one `RES-105-0715` and no duplicate protected state.
- Screenshot checkpoints are captured by
  `integration_test/retailer_controls_device_replay_test.dart` for screens
  101–105 and their completed outcomes.

## Remaining external blockers

- Inventory eligibility, reservations, disputes, recalls and transfers still
  use deterministic review data; production needs a server-authoritative stock
  ledger.
- AI grounding, role-scoped retrieval, model safety, audit logs and cost limits
  need the production AI gateway and authorization service.
- Staff invitations, accepted identities, devices, sessions and access history
  need production Firebase Authentication, claims and server-side policy.
- Settings versions, GST/licence evidence and readiness need durable,
  authorized production records.
- Refunds, replacements, evidence, customer messages and payment protection
  need the production order, payment and messaging providers.
- The build emits a future Flutter migration warning for plugins that still
  apply the Kotlin Gradle Plugin; it is not a current build or runtime failure.

## Evidence-based gate

The deterministic Flutter client slice for screens 101–105 is **GO** for
continued full-scale implementation. It is **NO-GO** for public stock
recovery, AI-assisted business actions, staff access, settings commitment or
customer-issue resolution until inventory, identity, authorization, AI,
payments, messaging and evidence are connected to server-authoritative
production services.
