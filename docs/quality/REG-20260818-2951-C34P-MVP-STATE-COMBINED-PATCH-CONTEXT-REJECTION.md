# REG-20260818-2951 C34P MVP-state combined patch rejection

Date: 18 August 2026 (IST)
State: registered before smaller state hunks

## Incident

The primary attempted one combined patch spanning the C34P current-ticket ID,
the complete selected robustness assessment and the retained C34L child-batch
label in the large MVP scope state. Patch verification could not match the
complete context and rejected the operation atomically. Readback rules treat
this as zero mutation; no runtime, test, provider, build, device, private or
external action followed it.

## Root cause

The patch relied on a long multi-field context across a dense, append-heavy
owner. Even though the relevant range had been read, one broad replacement made
the complete transition dependent on every rendered line matching exactly.

## Prevention

Patch the MVP state through small independent exact-context hunks: current
ticket identity, selected-assessment scalar groups, owner arrays, robustness
arrays, retained C34L label, top-level ticket, and execution/provider state.
Parse and project the exact changed values after every accepted hunk before the
next patch. Recompute the selected manifest hash from disk and run both machine
gates only after all bounded transitions are verified.

## Retained evidence

- `config/mvp-scope-gate-state.json`
- `config/codex-development-regression-registry.json`
- this incident record
