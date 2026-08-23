# REG2995 — C34P dirty-digest disposed exit-code recurrence

Date: 20 August 2026 (IST)
State: registered before digest retry

## Incident

The primary's first bounded raw-byte dirty-status digest produced the expected
bytes, records, SHA-256 and zero stderr bytes, but disposed the process before
projecting `ExitCode`. The required exit-code field was blank. No path body was
emitted and no repository or external state changed.

## Root cause

The diagnostic repeated REG2966 by releasing the process object before copying
its completed exit status into a stable scalar.

## Prevention

After both redirected streams are completely captured and `WaitForExit()` has
returned, copy `ExitCode` into a ticket-specific scalar. Only then dispose the
process and emit exactly bytes, records, SHA-256, stderr bytes and the retained
exit code. Reject any blank field.

## Retained evidence

- `config/codex-development-regression-registry.json`
- `docs/quality/CODEX-DEVELOPMENT-REGRESSION-MEMORY.md`
- `docs/quality/REG-20260818-2966-C34P-FACEBOOK-DIGEST-PROCESS-DISPOSED-BEFORE-EXITCODE.md`
