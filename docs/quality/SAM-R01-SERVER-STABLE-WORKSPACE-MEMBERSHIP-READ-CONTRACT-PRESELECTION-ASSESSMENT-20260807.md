# SAM-R01 preselection robustness and reuse assessment

Date: 7 August 2026
Ticket: `SAM-R01-SERVER-STABLE-WORKSPACE-MEMBERSHIP-READ-CONTRACT`
Classification: `mvp_required`

## Customer outcome

A Personal user can be offered only exact active workspace memberships owned
by the authenticated account and identified by stable server IDs. Revoked,
expired, cross-account, malformed or conflicting membership data fails closed.

## Reuse and duplicate inventory

- `apps/admin` already owns the separate role-gated Superadmin, Screen 156,
  29 profile targets and deterministic review-mode behavior. No new Admin UI
  owner is necessary for SAM-R01.
- `backend/functions/src/commerce/supply_participant_contract.ts` already owns
  stable identifiers, tenant/workspace checks, immutable records, aggregate
  versions, command fingerprints, idempotency receipts and audit events for
  exact seller capabilities. SAM-R01 reuses those patterns and does not alter
  that bounded owner.
- Flutter `JourneySession` and historical Work setup state are client/review
  state. They cannot establish server membership and remain unchanged.
- Repository searches found no general account-to-workspace membership domain
  owner. YouTube membership references are provider-channel memberships and
  cannot be reused as workspace authority.

## Implementation disposition and necessity

Disposition: `new_necessary_work` using existing backend contract patterns.
One new pure domain file and one colocated test file are necessary because
extending the supply-participant aggregate would merge seller capability
ownership with Personal account membership and create the wrong trust
boundary. New screens: none. New routes: none. New persistence/backend
endpoint: none. New build: none.

## Robustness coverage

Tests must cover valid active memberships; stable identifier validation;
account mismatch; pending, revoked and expired exclusion; exact duplicate
collapse; conflicting duplicate rejection; malformed timestamps; invalid
membership intervals; deterministic ordering; immutable input/output;
unknown-profile preservation without capability inference; and empty safe
results. Typecheck, backend tests, regression memory, delivery discipline and
MVP scope gates remain required.

## Exclusions and dependencies

Excluded: presentation, route, store, Firestore rule, callable function,
Firebase session, admin claim, live data, workspace creation, capability
activation, payment/provider action, APK/build/install, credentials, Production,
commit, push, deploy and promotion.

SAM-R01 has no external dependency for its pure domain contract. SAM-R02 and
later children retain Firebase emulator, authenticated session, role, policy,
reference, provider, device and founder release gates. Timeline impact is less
than one engineering day and remains inside the 60–75-day lock.
