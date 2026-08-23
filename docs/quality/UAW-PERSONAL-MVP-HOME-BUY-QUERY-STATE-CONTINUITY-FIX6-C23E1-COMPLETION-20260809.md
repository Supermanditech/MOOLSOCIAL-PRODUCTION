# C23E1 Home to Buy query-state continuity completion — 2026-08-09

## Outcome

Destination-opened Mool Home now replaces only Home with the exact selected
target, while root Home continues to push targets. Query-specific destination
pages use complete-URI identity. A visible Buy Medicine page truthfully owns
`/app/buy?sub=medicine` before and after router refresh, and Back restores the
prior destination context.

## Reuse and scope

- Reused `PersonalMoolRootV2`, the existing `moolOrigin` signal, GoRouter,
  shared main-destination pages and the existing C23 route matrix.
- Added no screen, route, backend owner, family, subaction or business state.
- Build and install remained closed; installed OPPO r60.21 was untouched.

## Verification

- no-diff Dart format: passed for the three focused files
- focused Flutter analysis: 4 items, no issues
- focused route and Buy continuity suite: 15 tests passed
- exact visible Medicine path/query before and after refresh: passed
- root Home push and destination-origin Back restoration: passed

The false base-route assertion and its complete route-owner diagnosis remain
retained under REG-20260809-580, REG-20260809-588 through REG-20260809-591.
