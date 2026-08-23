# REG2710 — post-C34H pre-ticket multifile read empty-pipe parse recurrence

## Observation

A read-only PowerShell wrapper intended to return eight required MVP
pre-ticket documents placed a pipeline directly after a statement-level
`foreach` block. PowerShell rejected the command during parsing. No document
content was read by that invocation and no product source, candidate, browser,
Play or OPPO state changed.

## Root cause

The wrapper repeated the empty-pipe command shape already prevented by the
regression memory: a statement-level loop was composed directly with
`ConvertTo-Json` instead of first collecting its output.

## Prevention

Do not retry the wrapper. Read each required document directly by literal
path, in bounded calls. When loop output must be serialized, assign it to a
task-specific variable and serialize that variable in a separate statement.
A parser rejection is zero reading or qualification evidence.

## Retained evidence

- `config/codex-development-regression-registry.json`
- `docs/quality/CODEX-DEVELOPMENT-REGRESSION-MEMORY.md`
- this record
