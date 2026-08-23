# REG-20260821-3052 auth callback trace broad rg and Windows wildcard path

## Observed failure

The callback trace grouped several large source roots and an invalid Windows
wildcard path. `rg` returned duplicate/truncated output plus a path error. The
trace is rejected.

## Root cause

The audit used a broad cross-root search instead of reading the already
identified callback gateway and session owners by exact literal file slices.

## Impact

- no source, ticket, test, build, Play, OPPO, provider or device action ran;
- no callback conclusion was accepted from the truncated output;
- no private value was read.

## Prevention and authorized continuation

Do not repeat cross-root callback searches. Read exact literal slices from
`journey_services.dart`, `review_journey_services.dart`, `journey_session.dart`
and the identified screen owner; use directory plus `-g` only if discovery is
strictly necessary.
