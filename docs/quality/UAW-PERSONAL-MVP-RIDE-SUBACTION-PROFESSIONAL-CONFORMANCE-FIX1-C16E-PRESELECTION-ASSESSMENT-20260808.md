# C16E Ride sub-action conformance preselection assessment

## Selected ticket

- Ticket: `UAW-PERSONAL-MVP-RIDE-SUBACTION-PROFESSIONAL-CONFORMANCE-FIX1-C16E`.
- Classification: `mvp_required`.
- Parent authority:
  `config/uaw-personal-mvp-global-subaction-professional-design-system-fix1-c16-ticket.json`.
- Predecessor evidence: Bike, Auto and Cab selected states are captured in the
  completed r60.15 OPPO audit.

## Customer outcome and reuse decision

Ride customers keep direct Bike, Auto and Cab selection in a compact centered
three-action family instead of three full-width distributed cells.

- Reuse `RidePageScaffold`, `RideSession`, `RideType.values`,
  `/app/ride/book?type=...` and all existing booking content and callbacks.
- Reuse the qualified C16A owner already connected with `familyId: 'ride'`.
- No duplicate renderer or new implementation owner is required; C16E is
  family-specific conformance, selection/state and content-reachability proof.
- Duplicate search is complete. No new action, route, screen, backend, service
  or state owner is necessary.

## Minimum complete scope

1. Prove the three-action cluster remains compact and centered at 320px/140%
   text, with every target at least 44x44.
2. Prove Bike, Auto and Cab remain one direct tap, selected semantics are inert
   and the existing booking state changes in place without a route reset.
3. Prove booking packages and primary controls remain reachable above the
   transparent navigation stack.
4. Prove finite family motion and immediate reduced motion.

## Explicit exclusions

- No pickup, destination, package, fare, payment, trip, safety, copy, route,
  session, backend or commercial-logic change.
- No filler action, menu, modal, palette or extra tap.
- No screenbook write, build, install, credentials, communication, payments,
  funds, Production, commit, push, deploy or promotion authority.

## Gate plan

- C16E static three-action/shared-owner and state-preservation gate.
- Ride focused compact/140%-text/semantics/reduced-motion test.
- Existing Ride vertical slice, C16A and C11 placement/motion regressions.
- Regression memory, MVP scope and delivery-discipline gates.
