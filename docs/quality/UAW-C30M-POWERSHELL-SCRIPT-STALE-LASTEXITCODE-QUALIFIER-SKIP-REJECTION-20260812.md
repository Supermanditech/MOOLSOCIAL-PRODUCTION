# C30M PowerShell-script stale-LASTEXITCODE qualifier-skip rejection

- ID: `REG-20260812-1451-C30M-POWERSHELL-SCRIPT-STALE-LASTEXITCODE-QUALIFIER-SKIP-REJECTION`
- Date: 2026-08-12
- Scope: local C30M provider-only qualification orchestration
- Result: regression gate passed but the qualifier was skipped; no cloud action occurred

The wrapper checked `$LASTEXITCODE` immediately after a successful PowerShell
script. A stale child-process value triggered an early shell exit, so the C30M
qualifier never ran even though the wrapper itself exited zero. C30M retries the
self-contained qualifier directly; its internal checked-command helper resets
the external exit code before every gate and treats thrown errors separately.
