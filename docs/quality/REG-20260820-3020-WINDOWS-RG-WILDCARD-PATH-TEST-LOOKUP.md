# REG-20260820-3020 Windows rg wildcard path test lookup

## Incident

After adding Firestore TTL timestamp fields to the X and Instagram OAuth
attempt documents, the primary attempted a read-only test lookup using
`backend/functions/src/auth/*test.ts` as a positional path. Windows rejected the
literal wildcard path with OS error 123 before ripgrep could search.

## Impact

- No test executed and no file, provider, deployment, build, Play or OPPO state
  changed.
- The failed lookup is not evidence of test presence or absence.

## Root cause

A Unix-style wildcard was supplied as a positional filesystem path instead of
using ripgrep's glob option against one literal directory.

## Prevention

Never retry the wildcard path on Windows. Pass the literal auth directory and
use `-g '*test.ts'`, then run the exact focused suites and full backend replay
before configuring Firestore TTL.
