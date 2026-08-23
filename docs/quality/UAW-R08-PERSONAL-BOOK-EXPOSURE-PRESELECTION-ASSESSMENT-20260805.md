# UAW-R08 Personal Book exposure preselection assessment

Date: 5 August 2026
Ticket: `UAW-R08-PERSONAL-BOOK-EXPOSURE`
Classification: `mvp_required`

## Customer outcome and reason

A Personal user taps Book and sees exactly **Doctor** and **Salon** as separate
intents. Each choice opens its existing booking owner in one tap. These are the
founder-retained Book capabilities for the launch MVP; Get It Done and broader
clinical/home-service promises are postponed.

## Reuse and smallest complete scope

- Reuse the R06/R07 `MvpActionChoiceRootV2`; create no Book landing screen.
- Reuse `/app/book/doctor`, `/app/book/salon`, `BookSession`,
  `DoctorBookingScreen` and `SalonBookingScreen`.
- Add only Doctor and Salon configuration to the shared action catalogue.
- Reuse the consolidated vertical action-root router branch without adding a
  route, session, controller, model or backend owner.
- Add only configuration/route-contract tests; reuse generic component,
  responsive, motion and semantics evidence from R06/R07.

Necessity proof: the existing `/app/book/home` presentation still includes the
postponed Get It Done path, while the exact Doctor and Salon downstream owners
already exist. Configuring the shared root is the only necessary runtime work.

## Explicit exclusions

- No Get It Done, Clinic, Hospital, home beauty or generic service exposure.
- No booking confirmation, payment, diagnosis, clinical record, provider,
  fulfilment, support or backend change.
- No new screen, route, session, controller, model or per-intent owner.
- No build, install, OPPO mutation, external-service action, credentials,
  commit, push, deploy, promotion or FIX7/baseline change.

## Dependencies, approval and verification

Dependencies: founder-preauthorized batch, completed R01/R03/R06/R07, existing
Book journey owner, native Flutter directive and 60–75 day reuse lock.

Verification: execution gate; exact human/machine route contract; focused
configuration and production-router tests; full analyze; R03/R06/R07 shared-
owner regressions; existing `book_vertical_slice_test.dart`; no build/device
action.

Estimated batch impact: **1 day**, within the locked delivery window.
