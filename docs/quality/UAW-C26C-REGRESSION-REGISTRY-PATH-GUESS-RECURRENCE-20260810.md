# C26C regression registry path-guess recurrence

## Observation

A registry inspection command guessed a nonexistent `codex-development-regression-memory.json` path and a guessed evidence filename.

## Cause

Verified permanent owner paths were not reused before the read-only inspection.

## Permanent prevention

- Use `config/codex-development-regression-registry.json` exactly.
- If an owner path is not already verified, list only bounded candidate filenames first.
- Keep the permanent memory wrapper as the machine prevention gate.

## Resolution evidence

The owner was resolved from bounded repository file results before any registry mutation or validation retry.
