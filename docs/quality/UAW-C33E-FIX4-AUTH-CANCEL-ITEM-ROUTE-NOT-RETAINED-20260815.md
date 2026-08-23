# UAW C33E FIX4 authentication cancellation item route not retained

Date: 2026-08-15
Regression: `REG-20260815-2353-C33E-FIX4-AUTH-CANCEL-ITEM-ROUTE-NOT-RETAINED`

## Observed failure

The strengthened guest Like regression correctly recorded the action-bearing success return, but `authenticationCancelFallback` remained `/app/social` rather than `/app/social?sub=feed&item=<id>` despite the consumer passing that exact cancellation route.

## Required investigation

Audit the existing `JourneySession.beginSignIn` and cancellation transition before retry. Determine whether the session intentionally normalizes the explicit cancel route or whether exact item cancellation is being lost. Do not weaken the assertion until the C30Z exact-origin cancellation contract is reconciled.

## Resolution

`beginSignIn` correctly stores the explicit route in `_authenticationCancelTo`, and `cancelSignIn` exposes it through `readyRoute()`. `authenticationCancelFallback` is intentionally the pre-authentication last-ready route used when a caller has not supplied an exact cancellation destination. The test asserted the wrong API. The retry must assert `readyRoute()` equals the exact item route and retain the action-bearing `returnTo` assertion.

No live authentication, build, provider, device or release action occurred.
