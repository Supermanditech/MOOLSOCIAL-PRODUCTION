# REG2900 — C34L readiness final-pin foreach-pipe parser recurrence

## Incident

On 2026-08-17, the readiness final-pin agent attempted to pipe directly from a statement-level PowerShell `foreach` block into `Format-Table` while rechecking final owner identities. PowerShell rejected the command with the known empty-pipe/parser class before the command body executed.

## Impact

- No owner identity was accepted from the failed command.
- No readiness, state, aggregate, candidate, seal, cycle, build, Play, OPPO, browser, private/account, device, secret, or external state changed.
- The agent stopped before inspection, retry, mutation, or testing.

## Root cause

The command repeated the registered statement-level `foreach ... } |` construction instead of materializing rows first or emitting one exact owner identity per command.

## Prevention

- Never pipe directly from a PowerShell statement-level `foreach` block.
- Assign loop results to a collection before formatting or serialization.
- For release-owner identity evidence, prefer one file per exact hash/byte/line command and avoid table formatting.
- Register this recurrence and replay the implementation regression-memory gate before readiness work resumes.

## Disposition

Registered truthfully before retry. Existing dual-host capture, transition, journal, retained, recovery, blocker, and readiness prerequisite results remain unchanged.
