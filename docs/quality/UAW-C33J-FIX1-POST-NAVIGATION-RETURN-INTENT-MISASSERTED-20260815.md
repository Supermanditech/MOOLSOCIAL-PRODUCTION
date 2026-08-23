# UAW C33J FIX1 post-navigation return intent misasserted

- Regression: `REG-20260815-2501-C33J-FIX1-POST-NAVIGATION-RETURN-INTENT-MISASSERTED`
- Failure: the first compiling FIX1 run passed foreground delivery and
  authentication but failed 1 of 3 because it expected `readyRoute()` to retain
  `/app/social?sub=create` after GoRouter had opened and confirmed that route.
- Finding: `confirmReadyRoute` intentionally consumes the one-shot pending
  authentication return. Its later fallback is not evidence of the current
  route or selected Social subaction.
- Prevention: assert the Create destination through the rendered selected
  semantics and retain independent completion-count assertions for one-shot
  behavior.
- Impact: no product source, external service, build, Play or device state was
  changed by the failing run.
- Correction after the next run: the exact destination was briefly reached but
  then overwritten by the foreground callback's second navigation after
  `returnTo` consumption. That runtime race is tracked separately as REG2502;
  this record retains only the invalid use of `readyRoute()` as a current-route
  oracle.
