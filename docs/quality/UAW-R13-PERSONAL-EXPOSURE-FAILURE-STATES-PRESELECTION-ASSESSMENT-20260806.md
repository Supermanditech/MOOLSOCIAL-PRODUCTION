# UAW-R13 Personal exposure failure states preselection assessment

Date: 6 August 2026
Ticket: `UAW-R13-PERSONAL-EXPOSURE-FAILURE-STATES`
Classification: `mvp_required`

## Customer outcome and reason

Loading, held, disabled, stale, offline and denied action-projection states
have one truthful, fail-closed native presentation contract. They never become
success, silently restore the legacy rail, disclose another workspace or allow
an unverified action to open.

## Reuse and smallest complete scope

- Reuse the R01 static projection fixture and its future
  `launch_policy_owner` boundary.
- Add one shared enum/spec table and one reusable native state panel; create no
  route-level screen or route.
- Keep the last safe context named in every state; allow Retry only for stale
  and offline, safe return for held/disabled/denied, and no synthetic action
  while loading.
- Add exact machine/human state contracts and deterministic widget/model tests.

Necessity proof: no shared native failure-state owner exists. Per-root state
widgets would duplicate copy and behavior, while wiring fabricated transitions
to the current static fixture would falsely claim live authority. One shared
panel is the minimum reference/native owner.

## Explicit exclusions

- No live projection fetch, connectivity monitor, authorization decision,
  geography/capability evaluation or server retry request.
- No local capability grant, fabricated liveness, success or authoritative
  failure transition.
- No root/router integration until a separately gated runtime projection owner
  supplies exact states.
- No screenbook/HTML, legacy Universal, vertical, backend or external-service
  change.
- No build, install, OPPO mutation, credentials, commit, push, deploy,
  promotion or FIX7/baseline change.

## Dependencies, approval and verification

Dependencies: founder-preauthorized batch, completed R01 reference projection,
completed R03/R06-R12 navigation owners, future server `launch_policy_owner`,
native Flutter directive and 60–75 day reuse lock.

Verification: execution gate; exact state/config identity; one active/no-panel
case; all six truthful panels; retry/safe-return callback ownership; no success
copy; full analyze; shared-root regressions; protected-state diffs; no
build/device action.

Estimated batch impact: **1 day**, within the locked delivery window.
