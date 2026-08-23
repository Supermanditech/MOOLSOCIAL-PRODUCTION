# Buy MVP Admin acceptance-SLA policy ticket

Prepared: 5 August 2026
State: **PLANNING COMPLETE — PORTFOLIO PREAUTHORIZED — EXECUTION NOT ACTIVE**
Ticket: `BUY-MVP-ADMIN-ACCEPTANCE-SLA-POLICY`
Portfolio: `BUY-MVP-READY-ORDER-DELIVERY-PORTFOLIO-20260805`
Classification: `mvp_required`

Relationship: this is bounded Child Ticket 1 of parent ticket
`BUY-MVP-READY-ORDER-TO-DELIVERY-END-TO-END-JOURNEY`. It owns only the global
Admin timing-policy foundation and relevant Journey 9 taps. The parent ticket,
not this child, contains the complete customer, Shop, Wholesale, Medicine,
provider, delivery, failure/recovery and Admin journeys.

## Customer and operator outcome

An authorized Commerce Policy Administrator can publish one bounded global
acceptance policy for each launch family. Every future order can refer to an
exact policy identity instead of relying on hard-coded, indefinite or silently
changed timing.

This ticket has no direct customer tap. Its customer value is the bounded
provider-response contract used by later assignment tickets. It does not start
assignment, send a message, call a provider, charge money or change an active
order.

## Why this is MVP required

Automatic failover cannot be trustworthy unless each provider attempt has an
authoritative duration, a bounded number of sequential attempts and a terminal
order-level ceiling. These facts are required before order snapshotting,
countdowns, escalation or reassignment can be implemented.

## Existing-surface reconciliation

The existing Superadmin is a separately deployed, role-gated Next.js
application. Production access currently denies by default until Firebase
session verification and server-side Admin claims are connected. Review mode
uses isolated evidence and cannot execute a real platform command.

The current Screen 150 Commerce prototype contains legacy `stock reservations`
and `Reserve` language. That language is not authority for this ticket and must
not be copied into the acceptance-policy journey. The founder's no-reservation
decision remains exact: readiness is not a hold, and stock commits only when a
later authorized provider-acceptance command succeeds.

The proposed Admin location is:

`Commerce -> Order acceptance policy`

with route intent:

`/admin/commerce?view=acceptance-policy`

The route and labels remain a presentation proposal until the applicable Admin
presentation authority is accepted. This document freezes behavior, not visual
design.

## Tap-to-tap Admin journey

### A. Open and inspect

1. Admin signs in through the verified Admin session.
2. Admin opens **Commerce**.
3. Admin selects **Order acceptance policy**.
4. The page verifies the Admin's tenant and
   `commerce.fulfilment_policy.admin` authority before retrieving policy
   existence, versions or values.
5. The page shows four family cards:
   - Shop;
   - Wholesale;
   - Medicine — non-prescription; and
   - Medicine — prescription after pharmacist-ready review.
6. Each card shows the current policy ID/version, effective time, per-provider
   response window, maximum sequential partners and overall ceiling.
7. A visible notice says that an edit applies only to future orders and cannot
   alter an active order.

### B. Create the first family policy

1. Admin selects a family without an existing policy.
2. Admin taps **Create policy**.
3. The form opens with the approved launch default for that family.
4. Admin sets **Provider response window** from 30 to 300 whole seconds.
5. Admin sets **Maximum sequential partners** from one to five.
6. The system derives **Maximum assignment time** as response window multiplied
   by maximum sequential partners. It is visible but not independently edited,
   preventing a truncated final provider attempt.
7. The system previews the deterministic per-attempt timeline:
   - MoolChat at zero;
   - WhatsApp at the floor of one-third of the response window;
   - agentic call at the floor of two-thirds; and
   - reassignment at expiry.
8. Admin chooses **Effective now for future orders** or a future effective
   timestamp. Backdating is rejected.
9. Admin enters an identifier-safe operational reason code.
10. Admin taps **Review policy**.
11. The review state shows previous value as `No policy`, the proposed values,
    calculated escalation instants and affected future-order family.
12. Admin confirms: **I reviewed the bounded wait, affected family and
    future-order-only effect.**
13. Admin taps **Publish policy**.
14. The server rechecks role, tenant, command identity, expected aggregate
    version, timestamps and every bound.
15. Success shows the immutable policy revision ID, aggregate version,
    effective time and audit reference.

### C. Revise an existing family policy

1. Admin selects the family card.
2. Admin taps **Create revision**.
3. Current values are copied into a new draft; the accepted stored revision is
   never edited.
4. Admin changes the response window or maximum partner count.
5. The overall ceiling and escalation preview recalculate immediately.
6. Admin chooses a non-backdated effective time and enters a reason code.
7. Admin taps **Review changes**.
8. The review state presents exact before/after values and explicitly says
   active orders keep their existing policy snapshot.
9. Admin confirms and taps **Publish revision**.
10. The server appends a new immutable revision and returns its exact identity.

### D. Failure and recovery states

- **Not signed in:** show Access Denied; retrieve no policy facts.
- **Wrong role or tenant:** show a generic denied result; change nothing and
  reveal no policy existence or value.
- **Window below 30 or above 300 seconds:** keep the form; identify the exact
  invalid field.
- **Partner attempts below one or above five:** keep the form; identify the
  exact invalid field.
- **Ceiling mismatch:** reject the command rather than silently rounding or
  shortening an attempt.
- **Backdated effective time:** reject with no revision created.
- **Stale aggregate version:** show that the policy changed, reload the newest
  version and require the Admin to review again.
- **Offline or transport failure:** retain the draft locally, say nothing
  changed and permit the same idempotent command to be retried.
- **Duplicate retry:** return the original success reference and create no
  second revision.
- **Conflicting reuse of a command ID:** reject and create no revision.

## Initial launch values

| Family | Response window | Maximum sequential partners | Derived overall ceiling | WhatsApp | Agentic call |
| --- | ---: | ---: | ---: | ---: | ---: |
| Shop | 60 seconds | 3 | 180 seconds | 20 seconds | 40 seconds |
| Wholesale | 180 seconds | 3 | 540 seconds | 60 seconds | 120 seconds |
| Medicine — non-prescription | 90 seconds | 3 | 270 seconds | 30 seconds | 60 seconds |
| Medicine — prescription after pharmacist-ready | 300 seconds | 2 | 600 seconds | 100 seconds | 200 seconds |

The WhatsApp and agentic-call instants are policy facts only. This ticket does
not authorize or execute either external channel.

## Minimum server-owned contract

The later implementation must provide:

- tenant-scoped `AcceptanceSlaPolicySet` identity and optimistic aggregate
  version;
- four exact launch-family values with no generic service family;
- append-only `AcceptanceSlaPolicyRevision` records;
- whole-second response windows from 30 through 300 inclusive;
- whole-number sequential-partner limits from one through five inclusive;
- a derived overall ceiling equal to response window multiplied by attempts;
- deterministic escalation offsets and explicit expiry;
- non-backdated, strictly ordered effective timestamps per family;
- exact command idempotency and conflicting-command rejection;
- authorization before existence/value lookup or stale-version checks;
- immutable command receipts and audit events containing governed IDs and
  hashes, not secrets or personal content; and
- an effective-at query that returns only the latest revision already effective
  at the requested instant.

## Smallest complete implementation slices

When later activated, this remains one logical ticket but executes in guarded
order:

1. Pure backend domain contract and deterministic unit tests.
2. Authorized persistence/command adapter only after its owner and environment
   are available.
3. Admin read/create/revise projection only after verified session/role claims
   and the presentation authority pass.
4. Review-mode and browser qualification proving denied, invalid, offline,
   stale, retry and success states without Production data.

If a held dependency prevents slices 2 or 3, the ticket may be recorded only as
locally technically qualified; it must not be represented as Production-live.

## Explicit exclusions

- market, locality, weekday/time-band and busy-schedule overrides — Ticket 2;
- order-level immutable policy snapshots — Ticket 3;
- provider Ready/Busy/Paused state — Ticket 4;
- policy history UI, maker-checker, rollback and tamper review — Ticket 5;
- offer readiness, reservation, stock or fulfilment logic — Tickets 6–11;
- payment, assignment, messaging, WhatsApp, calling or reassignment;
- Admin timer recommendations or autonomous policy application;
- unrelated phone activity, contacts, other apps, background location,
  microphone or private message collection;
- generic services, Eat, Ride, salon or doctor booking;
- Flutter/customer UI changes; and
- live credentials, external-service actions, deployment or Production writes.

## Dependencies and retained gates

- exact portfolio manifest SHA-256
  `5CE81AB6332607A71B960C57A1E99466109E13299CD8A5995FFC3163F35893AF`;
- existing Superadmin production session and role-claim owner;
- backend persistence/command environment owner;
- applicable Admin presentation authority before adding the proposed view;
- MVP scope machine activation before any backend/runtime write; and
- existing release, source-drift and evidence gates.

No external payment, WhatsApp, telephony or clinical credential is needed for
the pure policy contract.

## Test and evidence plan

### Backend contract

- all inclusive boundary values and adjacent invalid values;
- four-family isolation and unsupported-family rejection;
- derived ceiling and one-third/two-thirds rounding fixtures;
- invalid, missing, non-integer and unsafe numeric input;
- authorization-before-existence, cross-tenant and missing-scope denial;
- non-backdating and strictly ordered family revisions;
- exact idempotent retry and conflicting replay;
- optimistic version conflict and concurrent revision race;
- immutable inputs, outputs, receipts and audit events;
- effective-at boundaries immediately before, at and after revisions; and
- audit projection contains no email, phone, prescription, message or secret.

### Admin projection, when its gates pass

- keyboard and touch completion at desktop and 320-pixel width;
- 100%, 140% and 200% text scaling without hidden controls;
- loading, empty, denied, invalid, offline, stale, failure, retry, duplicate and
  success states;
- review step cannot be bypassed;
- active-order warning remains visible before confirmation;
- Back/refresh preserves no false success and never republishes; and
- two complete affected regressions from clean state.

## Acceptance criteria

The ticket is complete only when:

1. all four family policies can be represented without reservation semantics;
2. no accepted window, attempt limit or ceiling can exceed its bounds;
3. one policy revision cannot mutate a prior revision or an active order;
4. authorization occurs before policy existence or values are disclosed;
5. retry is idempotent and concurrency cannot silently overwrite a revision;
6. every successful command returns an exact revision and audit identity;
7. held live dependencies are accurately labelled rather than fabricated; and
8. the required focused, regression and drift evidence passes twice where the
   gate demands two passes.

## Next planning candidate

After this ticket is accepted as a planning contract, the next bounded journey
is `BUY-MVP-MARKET-SCHEDULE-TIMER-OVERRIDES`, which adds effective-dated market,
locality, weekday/time-band and declared-busy overrides without changing the
global family-policy contract above.
