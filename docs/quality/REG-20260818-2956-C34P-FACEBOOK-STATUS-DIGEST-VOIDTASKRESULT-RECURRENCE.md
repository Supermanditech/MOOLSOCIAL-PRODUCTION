# REG-20260818-2956 C34P Facebook status-digest helper recurrence

Date: 18 August 2026 (IST)
Task: `/root/auth_facebook`
State: registered before literal retry authorization

## Incident

During mandatory preflight, the Facebook subagent completed an in-memory raw-
byte `git status --porcelain=v1 -z` digest with exit zero, empty stderr and five
bounded scalar results. Two unsuppressed `GetAwaiter().GetResult()` helper calls
also emitted `System.Threading.Tasks.VoidTaskResult`, contaminating the exact
output allowlist. The subagent stopped before gates or implementation and did
not print any status body or path.

Both assigned source/test owners remained absent. No repository, test,
provider, browser, device, private, account or external state changed.

## Root cause

The subagent repeated the helper-return suppression failure already preserved
by REG2945: asynchronous stream-copy completion values were left on the
PowerShell success pipeline.

## Prevention and retry authority

Every `GetResult()`/stream-copy helper return is assigned to `$null` (or cast to
`[void]`) before the five allowlisted fields are emitted. The corrected command
must assert exactly five output lines and no `VoidTaskResult` text. Before the
subagent resumes, it must reread this literal incident path, refresh regression
memory, and pass its coordination gate against the primary-provided current
registry count and SHA.

## Retained evidence

- `config/codex-development-regression-registry.json`
- `config/codex-subagent-coordination-policy.json`
- this incident record
