# C23E1 active-configuration hypothesis rejection — 2026-08-09

## Retained trace

The focused diagnostic printed:

`C23E1_ROUTE_TRACE provider=/app/buy active=/app/buy`

Medicine customer content was visible at the same time. Therefore the route
information provider was not merely lagging the active GoRouter
configuration. The active route had collapsed to the older queryless Buy page
while the shared Buy session retained the transient Medicine selection.

## Permanent prevention

Route diagnosis must compare provider URI, delegate active URI, visible widget
and session state together. The next bounded trace records the active route
immediately after the target tap and across transition frames to locate the
collapse; no assertion will be weakened.

## Successor correction

The frame trace proved the delegate URI was already `/app/buy` while Mool Home
was visibly active. Therefore it was a base-route measurement, not the
imperative top-page owner, and the route-collapse conclusion was rejected by
REG-20260809-590. Visible-page `GoRouterState` is now the required owner.
