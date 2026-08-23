# C23E1 visible-page route-owner correction — 2026-08-09

## Retained proof

The bounded trace captured all route owners in the same journey:

- underlying base URI before the subaction: `/app/buy`
- visible Home page state: `/app/mool?from=buy`
- visible Buy page state after the tap: `/app/buy?sub=medicine`
- provider/delegate base URI after the tap: `/app/buy`

Medicine customer content was visible. This proves the implementation retained
the exact imperative target and the failing test asserted the wrong owner.

## Permanent correction

The focused continuity test now asserts `GoRouterState.of` from the visible
`buy-v2-screen` before and after a router refresh. It no longer treats the
underlying base route as the top page, and it retains exact path, query and
visible-content checks.
