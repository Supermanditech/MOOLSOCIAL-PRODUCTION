# REG3152 - Registry filename guess

## Classification

Registered read-only diagnostic failure with zero repository mutation.

## Evidence

The diagnostic attempted `config/regression-registry.json`, which does not exist. The authoritative registry remains `config/codex-development-regression-registry.json`.

## Prevention

Copy the authoritative owner path from coordination state. If recovery is necessary, use one config-scoped exact filename search before parsing.
