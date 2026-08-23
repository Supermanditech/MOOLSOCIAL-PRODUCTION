# C23G cycle 1 brand-launcher owner rejection — 2026-08-09

## Retained cycle result

Fresh cycle 1 passed:

- no-diff format for 17 files
- complete Flutter analysis with no issues
- all 98 tests across the 13 required files
- the C23 aggregate gate
- the placement regression gate
- approved UI and production locks

The next required gate rejected with: `Shared global navigation does not use
the canonical Mool launcher`. No final fingerprint seal was produced, so the
attempt counts as zero qualifying cycles. Its complete output is retained at
`artifacts/quality/uaw-c23g-host-qualification-20260809/cycle-1.log`.

## Required diagnosis

Compare the C23 single-launcher runtime source with the exact canonical brand
component rule in `check-brand-integrity.ps1`. Correct only the stale
authoritative owner; the brand gate remains mandatory and may not be bypassed.

## Diagnosis and correction

The C23 `_MoolHomeLauncher` already renders
`MoolBrand.moolLauncherIcon` directly inside `Icon(...)`. The retained gate
required obsolete rail-style named-parameter syntax,
`icon: MoolBrand.moolLauncherIcon`. The gate is corrected to extract the actual
launcher class boundary and require the canonical token within that owner; no
brand requirement is removed or weakened.
