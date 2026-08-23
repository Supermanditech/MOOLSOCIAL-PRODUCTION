# MoolSocial MVP scope execution policy

Authority date: 5 August 2026
State: founder-directed and active

## Outcome

Resume MoolSocial from the verified R58.8.8 FIX7 checkpoint while limiting new
development to the smallest complete MVP launch journeys. This policy prevents
an open backlog, a desirable enhancement or a broad production idea from
silently becoming current implementation scope.

## Mandatory pre-execution disclosure

Before any new ticket causes a runtime/backend write, build, device install or
external-service action, Codex tells the founder:

1. ticket ID and customer outcome;
2. classification: `mvp_required`, `mvp_supporting` or `beyond_mvp`;
3. why that classification applies;
4. the smallest complete implementation scope;
5. what is explicitly excluded;
6. dependencies and separate approvals still required; and
7. the automated and device evidence needed for completion.

The disclosure must be recorded in the ticket/candidate evidence and in
`config/mvp-scope-gate-state.json`. Run
`scripts/check-mvp-scope-gate-state.ps1 -RequireExecutionAuthorized` before the
first implementation write. An MVP classification is not authorization: all
existing founder, protected-reference, payment/provider, environment,
compliance and release gates continue to apply.

## Robust 60–75-day delivery and secondary selection checkpoint

The founder has locked a robust-MVP public-go-live planning window of 60–75
calendar days from 5 August 2026, or 4–19 October 2026. The durable authority is
`docs/delivery/MVP-ROBUST-60-75-DAY-DELIVERY-LOCK-20260805.md`; its machine
contract is `config/mvp-robust-60-75-day-delivery-lock.json`.

Before selecting or registering any successor ticket, including every
preauthorized child and any later separately authorized expansion, Codex must
pass the secondary checkpoint in
`docs/quality/MVP-PRE-TICKET-SELECTION-ROBUSTNESS-AND-REUSE-CHECKPOINT-20260805.md`.
It inventories existing owners, maps exact acceptance tickets to shared
implementation, searches for duplicate code/screens/routes/services and
records necessity for any new screen, route or backend owner. The resulting
assessment is pinned in `config/mvp-scope-gate-state.json`.

Codex may adjust execution topology through reuse, configuration, thin policy
adapters, test-only acceptance, shared implementation waves and dependency
ordering. It may not silently alter an approved customer outcome, actor,
capability, manifest/hash or gate. Such a material change needs a versioned
founder amendment. Schedule pressure never permits weaker security, privacy,
accessibility, truthful state, recovery, device or release qualification.

## Founder-locked SQL Connect completion rule — 22 August 2026

MoolSocial provisions and maps SQL Connect once from the complete production
contract. Frontend UI/UX journeys, main and sub-action outcomes, API contracts,
business rules, authoritative ownership, failure/recovery, privacy, retention
and relationship requirements must be complete before the final database map
is selected and provisioned.

- No repeated provisioning attempt, duplicate migration or exploratory live
  schema trial is allowed.
- No half-developed business logic, speculative table, provisional relation or
  incomplete main/sub-action domain may be encoded in SQL Connect.
- Before that completion gate, backend work is limited to already-complete
  shared global capabilities such as authentication/login and account erasure,
  or explicitly separate emulated/existing non-SQL-Connect backends.
- The prepared Dev SQL Connect creation action was cancelled before submission;
  its provisioning and migration counts remain zero.
- Reactivation requires the complete database map plus a fresh, exact founder
  authorization. The mandatory machine checks are
  `-RequireSqlConnectProvisioningAuthorized` and
  `-RequireSqlConnectMigrationAuthorized` on
  `scripts/check-mvp-scope-gate-state.ps1`.

## Classification

`mvp_required` means the ticket is necessary to complete or unblock a core
launch journey, correct a confirmed regression, satisfy security/privacy/legal/
accessibility truth, or qualify the launch safely.

`mvp_supporting` means a small, bounded improvement is necessary for a core
journey to be usable, recoverable or operable at launch. It must not introduce
optional product depth.

`beyond_mvp` means the work adds optional depth, speculative scale,
personalization, broad B2B/enterprise expansion, a deferred vertical, an
unapproved provider or AI capability, or design/motion work not required by a
confirmed launch need. It remains blocked until the founder separately
authorizes that exact expansion.

## Launch boundary

The governing launch slice remains `docs/delivery/45-DAY-GO-LIVE-PLAN.md`, as
refined by the founder's later exact action/provider decision in
`docs/delivery/MVP-FOUNDER-ACTION-PROVIDER-SURFACE-DIRECTIVE-20260805.md`:

- Social keeps Shorts, Videos, Feed and Create; final launch activation remains
  dependency-held by the current YouTube sequence, and Feed is bounded to
  native text and image-carousel posts;
- Buy keeps the complete Shop, Wholesale, Medicine and Orders journey with
  exact provider-type binding through delivery or accountable recovery;
- Eat is bounded to Order Food and Book Table; Tiffin is postponed;
- Ride is bounded to Bike, Auto and Cab with three separately authorized
  Captain types;
- Book is bounded to Individual Doctor and Salon / Parlour; Get It Done is
  postponed;
- standalone Pay and its sub-actions are postponed while approved payment
  integration remains embedded inside each authorized transaction journey;
- universal Work keeps Earn Today and Workspace, while Delivery, Onboard and
  Verify move inside their exact owning workspace; and
- Chat remains a global individual/shared/journey-context capability.

Broad B2B beyond the exact Wholesale contract, Cloud Kitchen, Tiffin, Clinic,
Hospital, generic services, home beauty, fleet, advanced POS, owned long-form
video, universal AI agents and non-launch workspace depth must not delay the
MVP. Ride, food, doctor and salon depth beyond the exact bounded journeys above
remains beyond MVP.

Confirmed navigation, accessibility, security, payment integrity, truthful
state, recovery and release defects in the supported launch slice may be MVP.
Speculative recommendations, autonomous behavior, optional platform breadth or
unmeasured scale work are not MVP merely because they are listed in a backlog.

## Current disposition

R58.8.8 FIX7 is founder approved/protected. No successor ticket is registered
or authorized by this policy refinement. The existing APK machine state
remains unchanged. Future
candidate registration must first replace the waiting state in
`config/mvp-scope-gate-state.json` with the disclosed, bounded ticket and its
existing authority; beyond-MVP authorization must be explicit and separate.
