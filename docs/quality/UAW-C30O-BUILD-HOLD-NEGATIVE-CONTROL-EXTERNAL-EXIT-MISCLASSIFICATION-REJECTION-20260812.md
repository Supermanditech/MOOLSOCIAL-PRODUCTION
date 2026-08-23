# C30O build-hold negative-control external-exit misclassification rejection — 2026-08-12

## Disposition

Rejected negative-control harness. The C30O build gate correctly rejected absent founder signing and secret-safe define inputs, but the parent PowerShell did not inspect the nested native process exit and then incorrectly raised `Negative control unexpectedly passed`. No build, device, provider, console or account state changed.

## Mistake

The harness wrapped a separately launched `powershell` process in `try/catch`, assuming its nonzero native exit would become a parent PowerShell terminating error.

## Root cause

Native-process exit semantics were confused with in-process PowerShell exception propagation.

## Prevention before retry

- Pass the permanent regression-memory gate.
- Capture the nested PowerShell output and immediate `$LASTEXITCODE`.
- Require nonzero exit and the exact expected rejection text; never infer success from `try/catch` around a native process.
