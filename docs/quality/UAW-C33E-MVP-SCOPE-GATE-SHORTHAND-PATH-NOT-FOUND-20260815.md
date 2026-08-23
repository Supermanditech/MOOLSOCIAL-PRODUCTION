# UAW C33E MVP scope-gate shorthand path not found

Date: 2026-08-15
Regression: `REG-20260815-2360-C33E-MVP-SCOPE-GATE-SHORTHAND-PATH-NOT-FOUND`

The final checkpoint command invoked `scripts/check-mvp-scope.ps1`, which does not exist. The regression-memory and C33E FIX4 gates in the same command completed successfully before PowerShell rejected the nonexistent third script path. No product, release, device, provider, or external-service state changed.

Recovery: register this command-selection error before retry, discover the exact repository-owned MVP scope gate with a bounded filename search, inspect its parameter contract, and run only the discovered path.
