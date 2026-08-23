# C20C guessed permanent-regression-memory document — rejection

- Date: 2026-08-08
- Scope: C20C host implementation only
- Mutation before rejection: none
- Device/build/install impact: none; closed

## Observed mistake

The recovery diagnostic correctly discovered
`config/codex-development-regression-registry.json`, but also attempted to read
a conventional `docs/quality/PERMANENT-REGRESSION-MEMORY.md` path that does not
exist.

## Permanent prevention

Use the discovered JSON registry as the authoritative permanent-memory owner.
Any prose evidence path must come from the repository inventory or an exact
registry entry; it must not be inferred from the memory concept.
