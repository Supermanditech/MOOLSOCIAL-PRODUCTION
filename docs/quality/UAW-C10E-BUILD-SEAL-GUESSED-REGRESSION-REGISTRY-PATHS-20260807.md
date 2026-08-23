# C10E build-seal regression registry path assumption

- Registry: `REG-20260807-228-C10E-BUILD-SEAL-GUESSED-REGRESSION-REGISTRY-PATHS`
- State: resolved; permanent gate active.

The first read-only C10E build-seal calculation guessed
`config/codex-development-regression-memory.json`. A follow-up inventory then
guessed `config/codex-regression-registry.json`. Neither path exists, so both
commands failed before any APK machine-state, build, install or OPPO mutation.

The durable owner is discovered from
`scripts/check-codex-development-regression-memory.ps1` and is exactly
`config/codex-development-regression-registry.json`. Future regression-entry
counts and registry reads use that checker-owned literal path; similar state
owners are read from their enforcing checker before a compound calculation.
