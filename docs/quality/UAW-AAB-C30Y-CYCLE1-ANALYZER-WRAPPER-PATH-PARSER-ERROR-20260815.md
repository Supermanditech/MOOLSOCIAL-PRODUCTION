# UAW AAB C30Y cycle 1 analyzer wrapper path parser error

Date: 2026-08-15
Regression: `REG-20260815-2200-AAB-C30Y-CYCLE1-ANALYZER-WRAPPER-PATH-PARSER-ERROR`
Status: registered before retry

## Finding

The first post-FIX5 cycle-1 analyzer wrapper failed PowerShell parsing before
`flutter analyze` started. A nested `GetFullPath` / `Join-Path` expression used
as the `Tee-Object` path had unbalanced parentheses. No analyzer log or exit
file was created, so the attempt is zero analyzer evidence.

No build, upload, activation, install, device, provider or credential action
occurred.

## Prevention

- Resolve exact repository-contained absolute log and exit paths into named
  scalars before `Push-Location`.
- Pass the resolved log scalar directly to `Tee-Object`.
- Capture the native analyzer exit immediately and use a new attempt stem.
- Never reuse the uncreated base path as if the parser failure were an
  executed analyzer attempt.

## Resolution

The corrected wrappers resolved repository-contained absolute log and exit
paths before changing directories. Both fresh qualifying cycles completed the
whole-mobile analyzer with `No issues found!` and native exit 0.

- `artifacts/quality/uaw-aab-preparation-regression-hard-gate-20260814-01/c30y-post-fix5-cycle-01-attempt-03-analyzer.log`
- `artifacts/quality/uaw-aab-preparation-regression-hard-gate-20260814-01/c30y-post-fix5-cycle-02-analyzer.log`
