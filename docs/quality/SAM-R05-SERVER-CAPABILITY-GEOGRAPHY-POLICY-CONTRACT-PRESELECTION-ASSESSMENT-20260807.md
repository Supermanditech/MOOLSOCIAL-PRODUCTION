# SAM-R05 preselection robustness and reuse assessment

Date: 7 August 2026
Ticket: `SAM-R05-SERVER-CAPABILITY-GEOGRAPHY-POLICY-CONTRACT`
Classification: `mvp_required`

## Customer outcome and disclosure

A workspace capability is available only for its exact approved profile type,
capability, category, service area and validity interval. Held, disabled,
expired, mismatched or ambiguous policy fails closed with a truthful machine
result rather than a local capability guess.

Smallest complete scope: one pure shared policy domain contract and exhaustive
local tests. Explicit exclusions: UI, screen, route, customer copy, persistence,
Firestore, callable/API endpoint, live role or policy data, workspace mutation,
provider/payment action, APK/build/install, credentials, Production, commit,
push, deploy and promotion.

## Reuse and duplicate inventory

`isSupplyCapabilityActive` already enforces time, category and service-area
qualifiers for seven supply participant types and four commerce capabilities.
Its boolean result and supply aggregate boundary cannot represent exact Food,
Doctor, Salon, Ride or Work policy, nor explain held/disabled/mismatch truth.
It remains unchanged and supplies the proven qualifier semantics.

The SAM-R01 stable membership owner supplies identity projection but does not
infer capabilities. The existing Admin 29-profile list remains registry input,
not runtime authority. Repository search found no general cross-vertical launch
policy owner.

## Implementation disposition and necessity

Disposition: `reuse` plus `new_necessary_work`. Add one pure general policy
contract and one colocated test file. New screens, routes, stores, endpoints
and builds: zero. A shared owner is necessary to prevent separate category/
geography logic in every exact participant adapter and stays distinct from
membership and supply aggregate ownership.

Robustness covers stable identifiers, canonical UTC validity, exact profile and
capability match, required/optional category and service-area qualifiers,
held/disabled truth, expired/not-yet-effective results, missing policy,
ambiguous overlap rejection, deterministic immutable output and input
nonmutation. SAM-R01 is complete. SAM-R02/R03 remain environment/session-held;
SAM-R04 retains its Admin reference gate, so dependency-safe reordering reduces
rework and remains within the 60–75-day lock.
