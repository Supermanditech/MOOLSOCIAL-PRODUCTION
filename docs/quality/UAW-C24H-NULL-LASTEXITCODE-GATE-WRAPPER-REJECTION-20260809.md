# C24H null LASTEXITCODE gate-wrapper rejection

Date: 2026-08-09
Regression: `REG-20260809-755-C24H-GATE-WRAPPER-TREATED-NULL-LASTEXITCODE-AS-FAILURE`

The gate-only qualifier preflight successfully ran the aggregate PowerShell
gate, then rejected because `$LASTEXITCODE` was null. PowerShell script errors
already propagate as terminating errors under the qualifier's stop policy;
`$LASTEXITCODE` is valid here only for native `dart` and `flutter` processes.
The wrapper must remove this check before preflight retry.

The wrapper now relies exclusively on terminating PowerShell gate errors.
