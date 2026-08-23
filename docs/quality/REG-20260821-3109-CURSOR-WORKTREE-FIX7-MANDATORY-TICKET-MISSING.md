# REG-20260821-3109 — Cursor worktree FIX7 mandatory ticket missing

Date: 21 August 2026
State: registered; retry blocked until ticket materialization

## Failure

Cursor stopped its read-only non-auth/FIX7 audit before execution when the
recorded mandatory ticket was absent from the isolated worktree:

`config/uaw-c34p-fix7-meta-account-data-erasure-ticket.json`

## Impact

- No Cursor audit or test ran.
- No Cursor report, product source, Desktop checkout, build, provider, Play or
  OPPO state changed.
- Cursor did not guess an alternative path and did not retry.

## Root cause

The primary worktree refresh reconciled registry gate/evidence owners but did
not reconcile every exact mandatory-read owner needed by the newly assigned
Cursor audit. FIX7 is a current primary ticket but is not itself a registry
evidence path.

## Prevention

Before dispatching a worktree audit, materialize every literal mandatory-read
owner from its recorded claim/task scope in addition to the registry evidence
closure. Copy the exact FIX7 ticket from the production checkout, verify byte
length and SHA-256 equality, refresh the registry/memory/policy binding, and
issue explicit retry authority with this literal REG path.
