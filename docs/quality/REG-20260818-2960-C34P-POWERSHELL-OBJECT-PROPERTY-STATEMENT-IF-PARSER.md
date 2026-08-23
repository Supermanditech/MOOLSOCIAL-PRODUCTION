# REG-20260818-2960 C34P PowerShell object-property statement-if parser

Date: 18 August 2026 (IST)
State: registered before corrected owner metrics

## Incident

The primary attempted a four-owner existence/line/byte metric projection using
statement-form `if` expressions directly as `PSCustomObject` property values.
PowerShell rejected the command before execution with a missing-closing-brace
parser error. It returned no owner metrics and changed no repository or
external state.

## Root cause

The inline object construction repeated the durable rule that statement-form
conditionals must be resolved into explicit ticket-named scalars before object
construction.

## Prevention

The corrected inventory computes `exists`, `lines` and `bytes` in independent
local variables inside the loop, then constructs a uniform row. Loop results
are materialized before JSON serialization. The parser-rejected form is never
retried, and each source owner is still read in its required bounded windows.

## Retained evidence

- `config/codex-development-regression-registry.json`
- this incident record
