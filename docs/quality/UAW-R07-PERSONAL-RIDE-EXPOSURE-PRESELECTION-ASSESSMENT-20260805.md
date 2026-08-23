# UAW-R07 Personal Ride exposure preselection assessment

Date: 5 August 2026
Ticket: `UAW-R07-PERSONAL-RIDE-EXPOSURE`
Classification: `mvp_required`

## Customer outcome and reason

A Personal user taps Ride and sees exactly **Bike**, **Auto** and **Cab** as
separate passenger intents. Each choice opens the existing Ride booking owner
with that vehicle type already selected. These daily-necessity actions are
founder-retained MVP launch capabilities.

## Reuse and smallest complete scope

- Reuse the R06 `MvpActionChoiceRootV2`; create no Ride landing screen.
- Reuse the existing `/app/ride/book?type=...` route, `RideSession`,
  `RideBookingScreen` and `RideType` query adapter.
- Extend the shared action-root policy catalogue with three Ride choices.
- Consolidate Eat and Ride through one router branch so R08 Book and R10 Work
  require configuration only.
- Add only configuration/route-contract tests; do not duplicate R06 generic
  component motion and viewport tests.

Necessity proof: the old Universal Ride presentation is founder-rejected and no
policy-correct Ride root exists, but every downstream intent owner already
exists. Configuration on the shared R06 owner is therefore the only necessary
new runtime work.

## Explicit exclusions

- No fare, booking confirmation, payment, driver allocation, live tracking,
  safety, support, cancellation, provider call/message or backend change.
- No new screen, route, session, controller, data model or per-vehicle owner.
- No build, install, OPPO mutation, external-service action, credentials,
  commit, push, deploy, promotion or FIX7/baseline change.

## Dependencies, approval and verification

Dependencies: founder-preauthorized batch, completed R01/R03/R06, existing Ride
booking owner, native Flutter directive and 60–75 day reuse lock.

Verification: execution gate; exact machine/human route contract; focused
configuration and production-router tests; full analyze; R06 generic-owner,
R03 Mool and existing Ride vertical regressions; no golden/build/device action.

Estimated batch impact: **1 day**, within the locked delivery window.
