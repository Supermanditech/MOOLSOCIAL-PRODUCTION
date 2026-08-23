# REG-20260818-2988 C34P cold social protected-return query canonicalization

Date: 18 August 2026 (IST)
State: registered, diagnosed as an invalid route fixture, and corrected

## Incident

The first serialized primary focused run passed 46 tests and failed 1. A cold
Instagram callback authenticated, bootstrapped and completed once, but the stored
protected destination `/app/social?sub=photos` was returned as `/app/social`.
The session's existing ready-route canonicalization removed the unsupported query
state. No provider, network, build or device action followed.

## Diagnosis

The existing accepted social sub-route allow-list is exactly `shorts`, `videos`,
`feed`, and `create`; `photos` is not a router-owned sub-route. Foreground exact
return to `videos` had already passed. The cold fixture was corrected to `feed`,
then the affected file passed 5/5 and the three-file focused set passed 47/47.

## Prevention and correction contract

Read the exact canonicalization allow-list before selecting protected-return test
fixtures. Preserve valid local query-bearing destinations and explicitly retain
fallback for unsupported, external, malformed or callback-derived destinations.

## Retained evidence

- `apps/mobile/lib/features/journey01/journey_session.dart`
- `apps/mobile/test/uaw_c34p_fix1a_apple_instagram_public_login_integration_test.dart`
- `config/codex-development-regression-registry.json`
- `config/codex-subagent-coordination-policy.json`
- this incident record
