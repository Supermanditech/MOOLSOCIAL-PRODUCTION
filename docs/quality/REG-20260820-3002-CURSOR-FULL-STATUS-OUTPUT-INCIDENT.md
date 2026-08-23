# REG3002 — Cursor full-status-output incident

Date: 20 August 2026 (IST)
State: registered from Cursor report before task registration or retry

## Incident

Cursor reported emitting a full Git status output for the preserved,
evidence-heavy MoolSocial worktree. The path inventory is not repeated or
retained in this evidence. The report did not authorize or establish any
repository, build, provider, Play, OPPO or external mutation.

## Root cause

The repository-specific prohibition on full dirty-tree output was not applied
before Cursor's status command. A general status command was treated as routine
inspection despite the mandatory non-emitting digest contract.

## Prevention

Cursor and every later task must read the current repository instructions and
regression memory before action. Git preservation uses independent branch and
HEAD scalars plus the in-memory porcelain byte/record/SHA/stderr/exit digest.
Only literal claim-scoped paths may be emitted. Full status output is never
retried.

## Retained evidence

- founder report in the `20-08-2026` production-auth task
- `AGENTS.md`
- `docs/quality/CODEX-DEVELOPMENT-REGRESSION-MEMORY.md`
- `config/codex-development-regression-registry.json`
