# UAW AAB C30Y FIX5 binder self-test stale historical manifest

Date: 2026-08-15
Regression: `REG-20260815-2197-AAB-C30Y-FIX5-BINDER-SELFTEST-STALE-HISTORICAL-MANIFEST`
Status: registered before retry

## Finding

The first PowerShell 7 binder contract attempt after the FIX5 generation
extension exited 1. Its positive self-test reused the historical post-FIX2
provisional source manifest, which correctly no longer matches the FIX5-updated
authoritative Flutter runner.

That historical manifest remains immutable and non-current by design. The
failed attempt is retained at:

- `artifacts/quality/uaw-aab-preparation-regression-hard-gate-20260814-01/c30y-fix5-binder-post-extension-pwsh-attempt-01.log`
- `artifacts/quality/uaw-aab-preparation-regression-hard-gate-20260814-01/c30y-fix5-binder-post-extension-pwsh-attempt-01.log.exit.txt`

## Required repair

Generate a unique one-row current probe manifest inside the existing isolated
self-test directory and bind it to one exact current stable owner. Real
historical qualification manifests remain untouched and are not self-test
fixtures for later source generations.

## Resolution

The binder now creates its probe manifest inside the unique GUID probe
directory and binds it to the current FIX3 ticket owner. The corrected contract
passed under PowerShell 7 and Windows PowerShell; the failed attempt remains
preserved.

- `artifacts/quality/uaw-aab-preparation-regression-hard-gate-20260814-01/c30y-fix5-binder-post-extension-pwsh-attempt-02.log`
- `artifacts/quality/uaw-aab-preparation-regression-hard-gate-20260814-01/c30y-fix5-binder-post-extension-winps-attempt-02.log`
