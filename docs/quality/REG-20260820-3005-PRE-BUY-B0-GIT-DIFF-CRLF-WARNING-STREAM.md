# REG3005 — Pre-Buy B0 Git diff CRLF warning stream

Date: 20 August 2026 (IST)
State: registered before any replacement diagnostic

## Incident

Cursor B0 reported that a read-only wrapper containing
`git diff --cached --quiet`, `git diff --quiet` and a conflict query emitted an
unbounded LF-to-CRLF warning stream with filenames because stderr was not
captured separately. The wrapper exited zero, no repository or external state
changed, and the result is rejected as audit evidence.

## Root cause

Multiple Git diagnostics shared the host output surface and allowed conversion
warnings with path bodies to escape instead of independently capturing stdout,
stderr and native exit status.

## Prevention

Do not retry the rejected command. Use in-memory process capture with separate
stdout and stderr and emit only bounded counts/hashes, or derive staged and
conflict state from the already bounded porcelain aggregate. Filename and
warning bodies are never emitted.

## Retained evidence

- founder report in the `20-08-2026` production-auth task
- `docs/quality/PRE-BUY-BASELINE-AUDIT-20260820.md`
- `config/codex-subagent-coordination-policy.json`
- `config/codex-development-regression-registry.json`
