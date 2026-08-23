# C24D repeated regression-registry path rejection — 2026-08-09

A compound diagnostic attempted to read regression state from the mobile
working directory and then repeated a nonexistent
`config/codex-development-regression-memory.json` filename from repository
root, despite discovery identifying the real owner.

All subsequent regression reads use the exact repository-root path
`config/codex-development-regression-registry.json`; mobile-relative source
inspection remains a separate bounded command.
