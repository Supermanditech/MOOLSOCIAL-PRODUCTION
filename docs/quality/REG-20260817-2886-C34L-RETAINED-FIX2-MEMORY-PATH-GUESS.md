# REG2886 — C34L retained FIX2 memory path guess

- Status: registered read-only path-guess failure after all three owner parsers passed.
- Mistake: the agent guessed nonexistent `docs/quality/IMPLEMENTATION-MEMORY.md` while looking for the already-qualified memory gate.
- Root cause: the exact durable memory owner and command were replaced with an inferred filename.
- Prevention: use `docs/quality/CODEX-DEVELOPMENT-REGRESSION-MEMORY.md` for bounded reading and run exactly `pwsh -NoProfile -File .\scripts\check-codex-development-regression-memory.ps1 -Phase implementation -BuildMode none`; never search for a guessed memory filename.
- Impact: no memory/fixture/owner/recovery execution, mutation, release, private, or external action followed.
