# C30W failed r60.47 build replay stale rejection-message assumption — 2026-08-14

## Mistake

A deliberate read-only replay of the failed r60.47 state through the C30W
`build` phase asserted that the exact rejection would be `Google server client
ID was not founder-qualified.` The current failed C30V state predates the
successor field and correctly rejected earlier with `runtime configuration
missing property: googleServerClientIdQualifiedByFounder`.

## Impact

The build gate rejected the candidate, no app-bundle command ran, no build,
upload, install, device, provider or credential action occurred, and no
authority or action count changed. The invocation is not accepted as an exact
negative-control pass because its assertion used a stale schema assumption.

## Root cause

The nested `runtimeConfiguration` property names were not enumerated from the
current failed candidate before composing the exact expected exception. The
gate contract was read, but the historical state schema was inferred from the
successor contract.

## Prevention

Before every negative release-state replay, enumerate the exact current nested
owner properties and derive the first fail-closed condition from that schema.
Historical states may fail earlier than successor states; any valid rejection
is retained, but an exact-message qualification is admitted only when its
expected exception is copied from the current gate and state boundary.

The permanent prevention owner is
`scripts/check-codex-development-regression-memory.ps1`.
