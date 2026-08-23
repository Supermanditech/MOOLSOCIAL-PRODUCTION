# C30K first Dev corpus apply opaque failure rejection

## Finding

The first exact `moolsocial-dev-503018` corpus apply compiled successfully, then exited with the deliberately redacted `runner_failed` result. The apply log contains no credential or provider payload. Because persona creation runs before post persistence, partial Dev Auth state is possible.

## Disposition

Rejected and registered as `REG-20260812-1407-C30K-FIRST-DEV-CORPUS-APPLY-OPAQUE-FAILURE-REJECTION`. No blind retry is permitted.

## Permanent prevention

Perform bounded readback of deterministic personas, post idempotency records and expected media prefixes before retry. Add safe operation-stage classification and preflight exact Auth, Firestore and Storage authority. Reconciliation must use the sealed identities and idempotency keys without enabling, updating, deleting or duplicating anything.
