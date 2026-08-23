# C30C truncated-suite exec-cell not-found rejection

- Regression: `REG-20260811-1369-C30C-TRUNCATED-SUITE-EXEC-CELL-NOT-FOUND-REJECTION`
- Date: 2026-08-11
- Observation: exec cell `1765` was no longer available after the rejected truncated wait.
- Consequence: no completion result is recoverable from that cell, and no pass is inferred.
- Prevention: rerun the exact suite with the complete output persisted to a fresh evidence file and expose only bounded exit/hash evidence.
