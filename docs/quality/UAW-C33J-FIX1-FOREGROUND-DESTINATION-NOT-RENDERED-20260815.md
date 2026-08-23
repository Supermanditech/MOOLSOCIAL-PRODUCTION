# UAW C33J FIX1 foreground destination not rendered

- Regression: `REG-20260815-2502-C33J-FIX1-FOREGROUND-DESTINATION-NOT-RENDERED`
- Failure: the supported foreground route callback completed authentication,
  but `screen04-rail-create` was absent after settling. The focused result is
  2 passed and 1 failed.
- Boundary: no external service, build, Play or device state changed.
- Root cause: completion notified GoRouter, which opened and confirmed the
  exact return destination. Before the observer resumed, confirmation consumed
  `returnTo`; the observer then called `readyRoute()` and overwrote the exact
  route with generic Social.
- Repair: capture a canonical non-persisted, one-shot completion destination
  before authentication notifies the router, then consume that exact value in
  the foreground observer after its await.
- Acceptance: the callback must render the exact Create subaction, not merely
  authenticate or fall back to a generic Social route.
