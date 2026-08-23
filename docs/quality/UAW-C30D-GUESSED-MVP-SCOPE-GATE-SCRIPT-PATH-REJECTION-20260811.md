# C30D guessed MVP scope-gate path rejection

- Regression: `REG-20260811-1371-C30D-GUESSED-MVP-SCOPE-GATE-SCRIPT-PATH-REJECTION`
- Date: 2026-08-11
- Rejected command: `scripts/check-mvp-scope-gate.ps1`; the path does not exist.
- Preserved results: the delivery-discipline and implementation-regression gates in the same batch passed independently.
- Prevention: resolve the exact repository scope-gate filename first and run it separately; a later zero exit code never masks an earlier missing command.
