# REG-20260818-2950 C34P MVP-state line-locator input shape

Date: 18 August 2026 (IST)
State: registered before corrected locator

## Incident

The primary attempted to discover top-level key line numbers in the large MVP
scope state by passing the complete line array through PowerShell
`Select-String -InputObject`. PowerShell treated the collection as the wrong
input shape, so the first required key was reported missing and the command
stopped. It emitted no state content and changed no file or external state.

## Root cause

`Select-String -InputObject` was used for a line-number operation that requires
the literal file-path parameter (or explicit indexed iteration). The collection
input did not preserve physical file line ownership.

## Prevention

For exact line-number discovery, call `Select-String -LiteralPath` once per
anchored top-level key and project only its scalar `LineNumber`. Never feed a
complete line array through `-InputObject` for physical line locations. Read the
resulting non-overlapping literal ranges only after every required key resolves
exactly once.

## Retained evidence

- `config/mvp-scope-gate-state.json`
- `config/codex-development-regression-registry.json`
- this incident record
