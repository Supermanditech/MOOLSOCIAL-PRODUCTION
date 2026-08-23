# C30T scope-state compound-patch exact sentence mismatch

- Regression: `REG-20260813-1962-C30T-SCOPE-STATE-COMPOUND-PATCH-EXACT-SENTENCE-MISMATCH`
- Date: 2026-08-13
- Scope: machine scope-state selection; the rejected patch made zero changes.

## Incident

A compound selection patch reconstructed one classification sentence without
the current word `Feed`. Exact verification rejected the entire patch.

## Required prevention

Patch scope-state selection fields in small, independent hunks copied from
fresh exact context. Register any rejection before retry.

This record creates no build, upload, install, deployment or device authority.
