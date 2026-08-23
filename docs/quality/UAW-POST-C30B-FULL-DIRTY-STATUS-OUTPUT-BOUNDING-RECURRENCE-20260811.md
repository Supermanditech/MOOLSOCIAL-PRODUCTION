# Post-C30B full dirty-status output-bounding recurrence

- Regression: `REG-20260811-1360-POST-C30B-FULL-DIRTY-STATUS-OUTPUT-BOUNDING-RECURRENCE`
- Date: 2026-08-11
- Failure: one serialization of the complete preserved worktree status exceeded the tool output boundary.
- Prevention: retain the complete inventory in ticket evidence, use bounded counts and hashes for reconciliation, and inspect only exact in-scope owner paths.
