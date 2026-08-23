# REG-20260821-3105 — Cursor worktree parent workspace AGENTS missing

Date: 21 August 2026
State: registered; retry blocked until prevention is applied

## Failure

After the primary refreshed the isolated Cursor worktree to registry generation
3075, the first coordination-gate replay stopped with:

`mandatory read is missing: ../AGENTS.md`

The separate worktree is rooted below `MOOLSOCIAL-WORKTREES`, so the gate's
parent-derived workspace path resolves to
`C:\GUARANTEED OUTCOME\MOOLSOCIAL-WORKTREES\AGENTS.md`, while the authoritative
workspace instruction is `C:\GUARANTEED OUTCOME\AGENTS.md`.

## Impact

- The refreshed registry, policy and registered evidence had already been
  copied and hash-verified.
- No Cursor audit read, test, source edit, build, provider, Play or OPPO action
  ran after the rejection.
- The isolated worktree branch and existing B1/B2 outputs were not changed by
  the failed gate.

## Root cause

The coordination checker assumes the repository's immediate parent is the
authorized workspace root. That assumption is false for the approved nested
worktree layout.

## Prevention

For this existing worktree, place an exact copy of the authoritative workspace
`AGENTS.md` at the parent path the checker requires, verify byte length and
SHA-256 equality, refresh the current registry binding, then replay the
regression and coordination gates before Cursor resumes. Future worktree
creation must qualify the parent workspace-instruction resolution before a
task is dispatched.
