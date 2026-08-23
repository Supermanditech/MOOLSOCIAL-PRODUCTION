# UAW-C33F FIX3 C30V manifest compare invoked on unsupported PS5.1

- Recorded at: `2026-08-15T10:53:41.6354441Z`
- Regression: `REG-20260815-2402-C33F-FIX3-C30V-MANIFEST-COMPARE-INVOKED-ON-UNSUPPORTED-PS51`

The C30V sealed-source manifest compare was unnecessarily invoked under Windows PowerShell 5.1. That host lacks the .NET `SHA256.HashData` API used by the established owner, so the extra invocation failed before producing comparison evidence.

No source file or manifest was written. The required comparison is rerun on PowerShell 7 only. Separate C33E and C33F implementation and expected-build-rejection gates already pass on both PowerShell hosts and remain the dual-host evidence.
