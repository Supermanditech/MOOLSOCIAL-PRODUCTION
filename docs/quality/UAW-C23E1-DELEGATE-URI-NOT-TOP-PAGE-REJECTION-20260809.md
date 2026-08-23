# C23E1 delegate URI is not the imperative top-page owner — 2026-08-09

## Retained frame trace

While the Mool Home page was visibly active, before the Medicine target tap,
the diagnostic reported:

`C23E1_ROUTE_TRACE before=/app/buy`

It then remained `/app/buy` immediately after the tap and across 300 ms. This
disproves the claim that `routerDelegate.currentConfiguration.uri` represented
the currently visible imperatively pushed page and disproves the route-collapse
conclusion drawn from that measurement alone.

## Permanent prevention

For imperative navigation, the visible page's `GoRouterState.of(context).uri`
is the route-state owner to test. Provider and delegate base URIs remain useful
separate evidence but cannot define the top page by themselves.
