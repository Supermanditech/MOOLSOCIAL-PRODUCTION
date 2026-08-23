# UAW C33J FIX1 exact route provider, blank delegate

- Regression: `REG-20260815-2507-C33J-FIX1-EXACT-ROUTE-PROVIDER-BLANK-DELEGATE`
- Evidence: the public GoRouter provider URI was exactly
  `/app/social?sub=create`; `tester.takeException()` was null; all bounded
  route-owner counts remained zero.
- Current result: the exact route is requested but not rendered; 2 of 3 focused
  tests pass.
- Next evidence: compare router-delegate configuration and bounded widget types
  before another product-source change.
- Boundary: no external service, build, Play or device state changed.
