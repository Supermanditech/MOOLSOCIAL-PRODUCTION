# UAW Personal navigation FIX3 preselection assessment

Date: 6 August 2026
Ticket/candidate: `UAW-PERSONAL-MVP-ACTION-WORDING-WIRING-NAVIGATION-FIX3`
Classification: `mvp_required`

## Confirmed customer defect

Physical OPPO qualification rejects FIX2/r60.5 on one exact supported path:
Ride `Cab -> Chat -> Back` returns to Bike. Cab is selected before Chat and
Bike is selected after Back. This loses the user's explicitly selected service
type and contradicts the authorized exact-return navigation outcome.

All FIX2 rail projection, selected styling, main/sub-action wiring, visible and
Android Back, Mool chooser restoration, lifecycle safety, protected Social and
protected Buy results otherwise pass on OPPO and remain the reusable baseline.

## Smallest complete scope and reuse

- Reuse `RideBottomDock`, `RideSession`, `createJourneyRouter`,
  `ChatInboxScreen`, `chatGoBack` and the existing `/app/ride/book?type=` route.
- Canonicalize the Ride booking Chat return from the selected `RideSession`
  type whenever the current owner is `/app/ride/book`; retain the current URI
  unchanged for trip/support owners.
- Strengthen the existing FIX2 widget acceptance so Chat Back must restore the
  exact selected Ride dock, not merely the generic booking screen owner.
- Re-run every FIX2 affected, protected and broad host gate before reserving a
  new one-build identity, then repeat the full OPPO audit.

No new screen, route, state, session, service, store, backend, provider,
payment or workspace owner is necessary. This is a thin canonical return-route
adapter in an existing owner plus acceptance coverage.

## Explicit exclusions

- No change to chooser/destination wording, rail layout, motion composition,
  Eat, Book, Work, protected Social or protected Buy runtime.
- No active ride creation, cancellation or reset; no live provider call.
- No backend/provider/payment activation, screenbook/reference/baseline change,
  OPPO uninstall/data clear/downgrade, credentials, funds, Production write,
  commit, push, deploy or promotion.
- No alteration or deletion of FIX1/r60.4 or FIX2/r60.5 source, APK, checksum,
  screenshot, XML, log or rejection evidence.

## Verification and timebox

Prove Bike, Auto and Cab each survive `Chat -> Back` with exact selected
semantics; prove cross-switching and active-trip protection; rerun format,
analysis, affected Personal/vertical suites twice, complete journeys twice,
protected Social, protected Buy twice, qualified mobile non-golden sweep twice,
release gates, unique identity, sealed source, signature, badging, in-place
install and full OPPO replay. Estimated impact: **under 1 day**, inside the
founder-locked 60-75-day window.
