# REG2898 — C34L primary-agent list output truncation

## Incident

On 2026-08-17, the primary agent requested an unfiltered collaboration-agent inventory while supervising the C34L FIX2 streams. The result included verbose completed-agent payloads and exceeded the available model context, so the tool output was truncated and was not accepted as complete monitoring evidence.

## Impact

- Read-only coordination output only.
- No repository, candidate, source seal, cycle, build, Play, OPPO, browser, private/account, secret, device, or external state changed.
- No child task was created, interrupted, or resumed by the failed read.

## Root cause

The primary used an unfiltered agent listing after a long multi-agent run instead of requesting a bounded path-scoped inventory or relying on already-known active task identities.

## Prevention

- Use `list_agents` only with the narrowest relevant `path_prefix` when an inventory is necessary.
- Prefer direct known-agent messages and bounded waits for current streams.
- Never treat a truncated collaboration inventory as complete status evidence.
- Register this recurrence and replay the implementation regression-memory gate before the next diagnostic, mutation, or qualification command.

## Disposition

Registered truthfully before any retry or later repository/test action. The known active streams remained `capture_artifact_fix2` and `auth_oppo_matrix_plan`; no device or external action was authorized by this incident.
