# C30O broad regression filename inventory output truncation rejection — 2026-08-12

## Disposition

Rejected read-only discovery attempt. No repository or external state changed.

## Mistake

The fallback `rg --files` inventory used broad regression globs and matched repository-wide historical artifacts, producing a truncated 1009-line result when only one registry path was needed.

## Root cause

The fallback search was not bounded to the `config` and `scripts` owners.

## Prevention before retry

- Pass the permanent regression-memory gate.
- Use the confirmed registry path directly.
- If discovery is ever needed again, constrain it to exact owner directories and cap output before execution.
