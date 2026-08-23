# UAW-R10 Personal Work exposure preselection assessment

Date: 6 August 2026
Ticket: `UAW-R10-PERSONAL-WORK-EXPOSURE`
Classification: `mvp_required`

## Customer outcome and reason

A Personal user taps Work and sees exactly **Earn Today** and **Workspace**.
Each choice opens its existing bounded Work owner in one tap. These are the
founder-retained Work entry intents for the launch MVP; Delivery Work, Onboard
and Verify are not separate launcher promises.

## Reuse and smallest complete scope

- Reuse the R06-R08 `MvpActionChoiceRootV2`; create no Work landing screen.
- Reuse `/app/work/earn`, `/app/work/my-work`, `WorkSession`,
  `WorkEarnScreen` and `MyWorkScreen`.
- Add only Earn Today and Workspace configuration to the shared action
  catalogue.
- Reuse the consolidated vertical action-root router branch without adding a
  route, session, controller, model or backend owner.
- Add only configuration/route-contract tests; reuse generic component,
  responsive, motion and semantics evidence from the shared owner.

Necessity proof: the existing legacy universal presentation separately exposes
Delivery, Onboard and Verify, while the two exact downstream Work owners and
routes already exist. Configuring the shared root is the only necessary
runtime work.

## Explicit exclusions

- No separate Delivery Work, Onboard, Verify, jobs-directory, salary or
  fee-to-work promise.
- No opportunity, eligibility, application, proof, review, workspace,
  settlement, payout, provider, support or backend behavior change.
- No new screen, route, session, controller, model or per-intent owner.
- No build, install, OPPO mutation, external-service action, credentials,
  commit, push, deploy, promotion or FIX7/baseline change.

## Dependencies, approval and verification

Dependencies: founder-preauthorized batch, completed R01/R03/R06-R09,
existing Work parent contracts and vertical owners, native Flutter directive
and 60–75 day reuse lock.

Verification: execution gate; exact human/machine route contract; focused
configuration and production-router tests; full analyze; prior shared-owner
regressions; existing `work_vertical_slice_test.dart`; no build/device action.

Estimated batch impact: **1 day**, within the locked delivery window.
