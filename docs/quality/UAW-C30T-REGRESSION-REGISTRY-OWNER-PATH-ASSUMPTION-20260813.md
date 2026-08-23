# C30T regression registry owner path assumption — 2026-08-13

## Outcome

A bounded read-only follow-up guessed a conceptual regression-memory filename
instead of the repository's canonical regression registry owner. The missing
path read failed and made no mutation.

## Root cause and prevention

A summarized concept label was converted into a filesystem path. Future
registry access first resolves an exact known REG identifier and then reuses
the literal returned owner path,
config/codex-development-regression-registry.json.

Because this registry evidence is source-sealed, both no-AAB qualification
cycles must be repeated before build authority can be activated.
