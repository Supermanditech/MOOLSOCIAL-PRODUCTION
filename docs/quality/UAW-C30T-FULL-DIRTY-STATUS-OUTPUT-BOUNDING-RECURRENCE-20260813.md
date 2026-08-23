# C30T full dirty-status output-bounding recurrence — 2026-08-13

A read-only reconciliation command ran unbounded `git status --short` in the known large dirty production tree and emitted thousands of user-owned paths. It did not mutate the tree, but the output was unnecessarily broad.

Prevention: use `git status --short -- <scoped owners>` for overlap checks, or pipe full status directly into a count/hash without printing individual paths.
