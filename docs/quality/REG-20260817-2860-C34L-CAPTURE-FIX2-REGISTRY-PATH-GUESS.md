# REG2860 — C34L capture FIX2 registry path guess

Date: 17 August 2026
State: registered read-only registry-path failure; zero mutation

## Mistake

The capture FIX2 agent guessed nonexistent
`docs/quality/regression-registry.json` for a latest-generation projection.
`Get-Content` failed and local `registryCount` was falsely reported as zero.
Branch, HEAD, and scoped status reads were unaffected; no mutation followed.

## Prevention

Use the authoritative registry path
`config/codex-development-regression-registry.json` exactly. Never infer a
docs/quality registry path; project count/hash only after successful parse of
the exact owner.
