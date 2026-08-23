# REG3000 — C34P X pure contract forbidden `offline.access` false pass

Date: 20 August 2026 (IST)
State: registered before source/test correction

## Incident

The focused X PKCE suite passed 12/12, but one test explicitly approved adding
`offline.access` when `refreshLifecycleEnabled` is true. The selected X child
ticket excludes refresh tokens and offline access, the production mobile
adapter accepts only `tweet.read users.read`, and the backend rejects any
refresh-bearing or overbroad grant. The unused pure contract and its gate could
therefore create a false qualification for a forbidden future configuration.

## Root cause

An optional protocol-planning branch survived the founder-corrected minimum
scope selection and the source gate asserted its literal instead of asserting
complete absence.

## Prevention

Remove `refreshLifecycleEnabled` and the conditional `offline.access` scope,
replace the permissive test with an exact-scope/absence assertion, and change
the shared source gate to reject `offline.access` in every X mobile/backend
owner. Rerun the pure X, mobile adapter and backend broker suites.

## Retained evidence

- `config/uaw-c34p-fix1-x-native-pkce-firebase-custom-token-broker-ticket.json`
- `apps/mobile/lib/core/auth/x_oauth2_pkce.dart`
- `apps/mobile/test/uaw_c34p_x_oauth2_pkce_test.dart`
- `backend/functions/src/auth/x_pkce_broker.ts`
- `config/codex-development-regression-registry.json`
