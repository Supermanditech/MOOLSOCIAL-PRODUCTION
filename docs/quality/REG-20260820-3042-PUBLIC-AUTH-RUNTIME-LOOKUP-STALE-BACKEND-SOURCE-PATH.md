# REG-20260820-3042 public-auth runtime lookup stale backend source path

## Observed failure

A read-only runtime-variable search included the nonexistent path
`backend/functions/src/publicAuth.ts`. `rg` returned partial mobile results and
exit code two. The partial output is rejected.

## Root cause

The lookup assumed a backend filename instead of resolving the current tracked
public-auth broker owner from the repository.

## Impact

- no repository, provider, build, Play, OPPO, account or device state changed;
- no source or test command ran;
- the partial lookup is not accepted as runtime-matrix evidence.

## Prevention and authorized retry

Discover the exact tracked broker owner with a bounded `rg --files` filter,
then search only existing literal paths. Never group an assumed path with valid
owners in one evidence command.
