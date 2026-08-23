# C30T backend diagnostic nonexistent test path

Date: 2026-08-13
Scope: read-only local diagnostic

## Observed failure

After the bounded backend log and qualifier assertion were already printed, the same `rg` command also received nonexistent path `backend/functions/test`. This repository's backend tests are under `backend/functions/src`, so `rg` returned exit 2.

## Prevention

Confirm paths with `rg --files` or `Test-Path` before searching and pass only existing exact directories. No repository or external state was mutated by the failed diagnostic.
