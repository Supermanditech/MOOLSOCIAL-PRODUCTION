# UAW C33J FIX1 test-binding route-information API guessed

- Regression: `REG-20260815-2500-C33J-FIX1-TEST-BINDING-ROUTE-INFORMATION-API-GUESSED`
- Failure: `TestWidgetsFlutterBinding` does not expose `handlePushRouteInformation`; the focused test produced four compile errors and ran zero tests.
- Impact: zero foreground-return test evidence; no external state changed.
- Prevention: consult the current official Flutter API and inject navigation only through a documented public testing/messenger surface.
- Resolution: Flutter documents `WidgetsBinding.handlePushRoute` as
  `@visibleForTesting`; it constructs `RouteInformation` and dispatches it to
  `WidgetsBindingObserver.didPushRouteInformation`. The focused matrix now
  uses that exact public test surface.
- Primary reference:
  <https://api.flutter.dev/flutter/widgets/WidgetsBinding/handlePushRoute.html>
