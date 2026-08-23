# C09 selected-Mool empty-callback interaction-gate failure

Date: 2026-08-07
Ticket: `UAW-PERSONAL-MVP-GLOBAL-MOOL-BOTTOM-RAIL-NAVIGATION-FIX1-C09-MOOL-HOME-RESELECT-BACK-STACK-MOTION`

## Failure

`scripts/check-interaction-contracts.ps1` rejected
`personal_mool_root_v2.dart` because the selected Mool action used
`onPressed: () {}`. The callback produced the required visible no-op but was an
empty visible action, which the production interaction contract forbids.

## Fix and prevention

`MoolDockAction.onPressed` is now nullable. Edge and middle dock items expose
their enabled semantic state from callback availability and pass the nullable
callback directly to `InkWell`. The current Mool Home item omits the callback,
so it is explicitly selected and disabled—not a fake working control. It has
no route, state, haptic, history or focus side effect.

Every future selected-root no-op must be represented as a disabled interaction
at the component boundary; empty callbacks are prohibited.
