# UAW-R01 preselection robustness/reuse assessment and disclosure

Date: 5 August 2026
Ticket: `UAW-R01-PERSONAL-ACTION-PROJECTION-CONTRACT`
State: `ASSESSED_AND_SELECTED_FOR_REFERENCE_CONTRACT_IMPLEMENTATION`

## Customer outcome and classification

The Personal user receives one versioned authoritative main/sub-action
projection instead of separate hard-coded action lists silently disagreeing.

Classification: `mvp_required`. The protected Flutter Screen 04 list currently
includes postponed standalone Pay, Tiffin, Get It Done and universal Delivery,
Onboard and Verify. The legacy `UniversalIntentCatalog` separately repeats
those choices. A single fail-closed contract is required before the connected
MVP reference can truthfully expose Social, Buy, Eat, Ride, Book and Work with
global Chat.

## Reuse and duplicate inventory

Existing owners inspected:

- `apps/mobile/lib/ui_v2/social/screen04_universal_components.dart`:
  `Screen04World`, `Screen04Choice`, `screen04Worlds` and current native V2
  presentation;
- `apps/mobile/lib/features/journey01/universal_intent_catalog.dart`: legacy
  intent content retained for containment, not promoted as the new authority;
- `apps/mobile/lib/features/journey01/journey_router.dart`: existing route
  owner to be reused by later integration;
- `contracts/journeys/PROD-JRN-001-ACCOUNT-SETUP-UNIVERSAL-ENTRY.md`: existing
  login/Universal entry journey contract; and
- approved Screen 04 reference packages and the screenbook Universal page,
  which remain unchanged by R01.

Duplicate-search result: there are two separate hard-coded presentation/action
catalogues but no reusable versioned launch-projection contract. R01 therefore
adds one data contract and one validator; it does not add a screen, route,
service, controller, state owner or backend owner.

Implementation disposition: `configuration` plus deterministic contract
verification. Later reference/native children consume the same contract rather
than creating per-surface or per-user-type lists.

## Smallest complete R01 scope

1. Add one versioned machine-readable launch action-projection contract with
   stable action/sub-action IDs, exact visible labels, disposition, route-owner
   reference and removed-action recovery intent.
2. Define the founder-approved MVP projection: Social, Buy, Eat, Ride, Book and
   Work; global Chat; no standalone Pay.
3. Represent YouTube-held and other held states truthfully without activating
   them locally.
4. Add strict validation for unknown/duplicate IDs, missing route owners,
   prohibited visible actions, missing expiry/effective identity and local
   capability grants.
5. Add positive and fail-closed negative fixtures/tests.

## Explicit exclusions

- No screenbook or approved-reference mutation/freeze.
- No visible Flutter presentation or route change in R01.
- No workspace registry, Admin mutation, geography, licence, subscription,
  payment, vertical backend or provider implementation.
- No build, install, OPPO replay, external service action, commit, push,
  deployment or promotion.

## Dependencies and approvals

- Parent manifest:
  `config/mvp-universal-action-workspace-routing-reference-batch.json`, SHA-256
  `45D765390EA6B2D94F334CB4F5B2AB67162657A447B220A10650EB7621DB34A8`.
- Founder preauthorization and non-stop start evidence:
  `docs/quality/MVP-PREAUTHORIZED-NONSTOP-EXECUTION-START-AUTHORIZATION-20260805.md`.
- Visible HTML/native consumption remains gated by the connected reference and
  exact founder-FINAL sequence.
- Server delivery of a later projection remains a separately owned backend
  dependency; R01 defines the contract and safe static MVP reference fixture.

## Test and evidence plan

- Parse every positive and negative JSON fixture.
- Verify exact six main actions, global Chat, exact sub-actions and prohibited
  action absence.
- Reject duplicate/unknown IDs, visible Pay/Tiffin/Get It Done/universal
  Delivery-Onboard-Verify, missing route owner, local grant claims and invalid
  version/effective/expiry boundaries.
- Run the dedicated validator under PowerShell 7 and Windows PowerShell 5.1.
- Run JSON parsing, protected manifest hash checks and scoped diff hygiene.

Timeline impact: one engineering day or less. The work remains within the
60–75-day lock and prevents duplicate implementation in later children.
