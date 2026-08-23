# REG3153 - Broad registry search output truncation

## Classification

Registered read-only output truncation with zero repository mutation.

## Evidence

The fallback file search matched 516 repository paths and its output was truncated. No success was inferred from the truncated result; a later exact authoritative path parse established the registry state.

## Prevention

Constrain recovery searches to `config/codex-development-regression-registry.json` and emit only the exact match needed.
