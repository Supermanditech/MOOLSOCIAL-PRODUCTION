# REG2998 — C34P App Check session-token/replay-protection mismatch

Date: 20 August 2026 (IST)
State: registered source defect before correction or test

## Incident

The X/Instagram backend verifies every public-auth request with
`verifyToken(token, { consume: true })` and rejects `alreadyConsumed`, but the
mobile supplier uses `FirebaseAppCheck.instance.getToken()`. Firebase's current
custom-backend replay-protection contract requires the client to acquire a new
limited-use token for an endpoint that consumes tokens. The green adapter tests
inject an opaque synthetic token and do not execute the production supplier, so
they cannot detect this client/server contract mismatch. No live request ran.

## Root cause

Backend replay protection and mobile App Check acquisition were implemented in
separate owners without an executable composition test binding the consumable
server contract to Flutter's limited-use-token API.

## Prevention

Use `FirebaseAppCheck.getLimitedUseToken()` at the public-auth supplier, reject
blank results, and add a source/integration assertion that the production owner
uses only the limited-use API for the replay-protected X/Instagram endpoint.
Retain backend `consume: true` plus `alreadyConsumed` rejection. Add founder
readback of the required Firebase App Check Token Verifier IAM role to the live
configuration ledger; do not perform that external write in this source ticket.

## External source qualification

Firebase, **Verify App Check tokens from a custom backend**, replay protection
section (read 20 August 2026):
`https://firebase.google.com/docs/app-check/custom-resource-backend`.

## Retained evidence

- `apps/mobile/lib/main.dart`
- `apps/mobile/test/uaw_c34p_x_oauth2_pkce_network_adapter_test.dart`
- `backend/functions/src/index.ts`
- `config/codex-development-regression-registry.json`
