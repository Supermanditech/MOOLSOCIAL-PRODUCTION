# UAW C33E action-intent audit Windows ripgrep wildcard and stale-path rejection

Date: 2026-08-15
Regression: `REG-20260815-2350-C33E-ACTION-INTENT-AUDIT-RG-WILDCARD-AND-STALE-PATH-REJECTED`

## Failure

A read-only exact-action contract search passed Windows wildcard path arguments directly to ripgrep and also named a stale guessed C30Z state path. Ripgrep rejected the paths and returned no complete contract evidence.

## Root cause and recovery

The command repeated the registered Windows rule requiring a literal directory plus `--glob`, and it guessed a historical filename instead of discovering it with `rg --files`. The failed output is discarded. Retry must first discover literal candidate paths, then search only existing literal files and use `--glob` solely as a filter.

No source, scope, build, device, provider or release state changed.
