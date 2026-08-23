# REG-20260821-3124 — Data Connect SQL-diff read exit one

Date: 21 August 2026
State: registered; Data Connect validation remains pending

## Failure

The no-apply `dataconnect:sql:diff` read returned native exit 1, 89 output
bytes, one error line and no SQL diff lines.

## Impact

- No Cloud SQL mutation or migration command ran.
- No source, deployment, build, provider, Play, OPPO or private state changed.
- Data Connect validation is not claimed complete.

## Root cause

The local CLI/read context could not complete the direct SQL-diff surface after
the emulator path had already been rejected.

## Prevention and disposition

Do not retry or seek token/credential workarounds in this phase. Retain the
exact Data Connect mutation source and official Admin SDK contract, keep live
schema validation explicitly pending, and require a later founder-controlled
authenticated validation window before deployment or release completion.
