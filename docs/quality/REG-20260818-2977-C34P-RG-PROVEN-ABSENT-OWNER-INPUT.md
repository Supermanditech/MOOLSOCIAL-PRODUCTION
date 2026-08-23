# REG-20260818-2977 C34P rg proven-absent owner input

Date: 18 August 2026 (IST)
State: registered before any corrected search

## Incident

A bounded primary inventory first proved that the planned FIX1 integration-test
owner did not exist, but the same command then passed that absent path to `rg`
alongside existing source files. `rg` emitted a native missing-file diagnostic.
The useful existing-file matches were read-only; all agents were stopped before
further mutation or test work.

## Prevention

Build targeted search inputs only from paths proven to exist, or search a bounded
existing directory with an exact include pattern. Treat planned-but-absent owners
as creation targets, never as direct native-command inputs.

## Retained evidence

- `config/codex-subagent-coordination-policy.json`
- `config/codex-development-regression-registry.json`
- this incident record
