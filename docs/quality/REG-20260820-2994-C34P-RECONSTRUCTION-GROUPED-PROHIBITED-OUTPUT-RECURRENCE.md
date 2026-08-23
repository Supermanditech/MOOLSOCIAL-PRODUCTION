# REG2994 — C34P reconstruction grouped prohibited output recurrence

Date: 20 August 2026 (IST)
State: registered before any retry, test or runtime mutation

## Incident

The resumed primary reconstruction combined the two mandatory `AGENTS.md`
reads with `git status --short --branch` and a raw full
`ACTIVE-CODEX-HANDOFF.md` read. The status and handoff output were truncated,
and the command emitted the complete dirty-path inventory class that repository
instructions prohibit. No repository or external state changed.

## Root cause

The primary began the diagnostic concurrently before independently applying
the repository-specific bounded reconstruction algorithm, repeating the
grouped-owner recurrence already prevented by REG2965 and the permanent dense
handoff/dirty-tree rules.

## Prevention

Read the workspace and repository instruction owners in separate results.
Discover only the first two handoff headings and read only the leading section
in non-overlapping bounded pages. Read branch and HEAD as independent scalars,
and use only the non-emitting in-memory status digest with no path output.

## Retained evidence

- `AGENTS.md`
- `docs/quality/ACTIVE-CODEX-HANDOFF.md`
- `docs/quality/CODEX-DEVELOPMENT-REGRESSION-MEMORY.md`
- `config/codex-development-regression-registry.json`
