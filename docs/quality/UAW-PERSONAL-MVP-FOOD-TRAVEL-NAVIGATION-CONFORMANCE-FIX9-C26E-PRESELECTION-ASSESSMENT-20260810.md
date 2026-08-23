# C26E Food and Travel navigation conformance preselection

Classification: `mvp_required`

## Customer outcome

Food and Travel keep their accepted transaction screens and direct actions under the completed transparent rail and embedded Mool switcher. Bus remains a Travel action while reusing the existing Book booking route, session and gateway.

## Scope, reuse and duplication decision

- Runtime implementation disposition: reuse only; no runtime mutation authorized.
- Existing owners: `EatPageScaffold`, `EatSession`, `RidePageScaffold`, `RideSession`, Book Bus route/session/gateway and `MoolDestinationNavigationV2`.
- No new screen, route, subaction, session, state or backend owner.

## Focused proof

- Food: root, Order Food and Book Table remain direct.
- Travel: root, Bike, Auto, Cab and Bus remain direct.
- Bus remains projected under Travel while retaining the truthful Book implementation owner.
- The shared rail has no old scroll, strap, capsule or themed action background.
- First Back closes Mool while preserving exact Food or Travel state.

Build, installation and external writes remain unauthorized in C26E.
