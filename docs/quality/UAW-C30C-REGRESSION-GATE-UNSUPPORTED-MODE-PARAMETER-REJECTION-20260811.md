# C30C regression-gate unsupported parameter rejection

- Regression: `REG-20260811-1368-C30C-REGRESSION-GATE-UNSUPPORTED-MODE-PARAMETER-REJECTION`
- Date: 2026-08-11
- Rejected command: `check-codex-development-regression-memory.ps1 -Mode implementation`.
- Result: PowerShell rejected the unsupported parameter before the gate executed; this is not a gate pass or product-test result.
- Prevention: inspect the script parameter block and invoke only its declared contract.
