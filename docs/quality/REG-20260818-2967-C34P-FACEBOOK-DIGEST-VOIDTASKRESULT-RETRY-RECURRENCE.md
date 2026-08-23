# REG-20260818-2967 C34P Facebook digest VoidTaskResult retry recurrence

Date: 18 August 2026 (IST)
Task: `/root/auth_facebook_native`
State: registered before final corrected preflight authorization

## Incident

On the authorized REG2966 retry, the Facebook native subagent correctly copied
`exitCode=0` before process disposal, but an unsuppressed
`$stdoutTask.GetAwaiter().GetResult()` emitted a sixth
`System.Threading.Tasks.VoidTaskResult` line. The five mandatory digest fields
were otherwise bounded and stderr was empty. The exact five-line allowlist
therefore failed and the subagent stopped before any repository, package,
parser, test or external action.

The X broker and X mobile owners again stopped before their gates or any
mutation when the primary announced registry movement.

## Root cause

The correction addressed process lifetime but did not apply helper-return
suppression to every asynchronous completion call, repeating REG2945 and
REG2956.

## Prevention and retry authority

Assign both stdout and stderr task `GetResult()` returns to `$null` (or cast
them to `[void]`), assert the captured output collection contains exactly five
lines before emitting it, and reject any line containing `VoidTaskResult`.
After the refreshed memory and coordination gates, this is the only authorized
digest retry form. A third recurrence stops the Facebook subagent permanently
and transfers the claimed work back to the primary.

## Retained evidence

- `config/codex-development-regression-registry.json`
- `config/codex-subagent-coordination-policy.json`
- this incident record
