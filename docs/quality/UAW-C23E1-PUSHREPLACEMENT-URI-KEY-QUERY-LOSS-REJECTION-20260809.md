# C23E1 pushReplacement and URI-key query-loss rejection — 2026-08-09

## Observed rejection

Focused analysis passed. The focused routing suite passed 14 assertions and
failed its critical real-router continuity assertion: after destination Mool
Home opened Buy Medicine, the Medicine view was visible but GoRouter's current
URI was `/app/buy`, not `/app/buy?sub=medicine`.

## Rejected assumption

Changing destination-origin dispatch to `context.pushReplacement(route)` and
keying the shared destination page with the complete URI did not stop a later
owner from rewriting or reporting the queryless Buy route.

## Required diagnosis before retry

- Trace the exact Home target string.
- Inventory every GoRouter redirect and every navigation call that can write
  `/app/buy`.
- Trace Buy destination synchronization during the first post-navigation
  frames.
- Keep the exact visible-view/current-URI assertion; do not weaken it.

C23E1 remains open and C23G qualification remains closed.

## Successor correction

The retained frame trace proved no visible-page query loss. Mool Home owned
`/app/mool?from=buy` and the visible Buy page owned
`/app/buy?sub=medicine`; only the underlying base URI remained `/app/buy`.
REG-20260809-591 corrects the test to use visible-page `GoRouterState` while
preserving exact path, query, refresh and customer-content assertions.
