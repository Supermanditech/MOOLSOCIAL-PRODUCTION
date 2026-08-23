# REG3070 — sideload self-test owner policy second context mismatch

- Date: 2026-08-21
- Status: registered before retry

## Incident

The second owner-policy patch still assumed a trailing conventional JSON line
for the existing sideload preparation script. `apply_patch` rejected the hunk
because the live owner tail uses a leading comma on that line.

## Impact

No policy, repository, build, device or external state changed.

## Prevention

After any patch-context failure, inspect the exact raw line range and reproduce
its literal punctuation before retrying. A parsed projection is insufficient
for patch context.
