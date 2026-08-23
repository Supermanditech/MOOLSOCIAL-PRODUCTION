# C30B machine-state root-field assumption rejection

- Regression: `REG-20260811-1359-C30B-MACHINE-STATE-ROOT-FIELD-ASSUMPTION-REJECTION`
- Date: 2026-08-11
- Scope: final C30B OPPO review-state reporting.
- Failure: a read-only summary queried nested values as root properties, producing misleading PowerShell defaults.
- Permanent prevention: inspect the exact sealed schema first, use only proven property paths, and never report casts of absent properties.
