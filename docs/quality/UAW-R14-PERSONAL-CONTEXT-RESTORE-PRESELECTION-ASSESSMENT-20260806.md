# UAW-R14 Personal context restore preselection assessment

Date: 6 August 2026
Ticket: `UAW-R14-PERSONAL-CONTEXT-RESTORE`
Classification: `mvp_required`

## Customer outcome and reason

Back, Chat return, process interruption and relaunch restore a safe permitted
Personal action or sub-action context. Removed, malformed, external and unknown
locations never become a restored capability.

## Reuse and smallest complete scope

- Reuse `JourneySession.lastReadyRoute`, its ordered snapshot persistence and
  the production router's existing ready-route confirmation.
- Reuse the existing Buy resume canonicalizer, R11 Chat return parameter and
  R03/R06-R10 Personal main/sub-action routes.
- Extend only the existing central persisted-ready-route canonicalizer with an
  exact allowlist and safe depth reduction; add no store, screen, route,
  session, service or backend owner.
- Add exact machine/human mapping contracts and deterministic session/router
  tests, while reusing prior Back and Chat-return acceptance suites.

Necessity proof: the existing owner already persists and restores routes, but
currently collapses non-Buy Personal contexts and Chat interruptions to Social.
A narrow extension of that owner is the minimum complete correction; a new
navigation store or per-vertical restore service would duplicate authority.

## Explicit exclusions

- No restoration of removed Pay, Tiffin, Get It Done, Delivery, Onboard or
  Verify actions as capabilities.
- No exact transaction/order/trip/booking/opportunity identifier persistence;
  deeper permitted routes reduce to their safe owning sub-action/root.
- No external/absolute/malformed/unknown route, cross-workspace or local
  entitlement restoration.
- No new storage key, migration, screen, route, backend or external-service
  owner.
- No screenbook/HTML or legacy Universal edit.
- No build, install, OPPO mutation, credentials, commit, push, deploy,
  promotion or FIX7/baseline change.

## Dependencies, approval and verification

Dependencies: founder-preauthorized batch, completed R01-R13 Personal action
and continuity owners, existing JourneySession/SharedPreferences store, native
Flutter directive and 60–75 day reuse lock.

Verification: execution gate; exact mapping/config identity; main/sub-action
relaunch; Chat interruption origin unwrapping; unsafe/removed fail-closed
cases; production-router relaunch; prior Back and Chat suites; full analyze;
protected-state diffs; no build/device action.

Estimated batch impact: **1 day**, within the locked delivery window.
