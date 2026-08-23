# C25 guessed delivery/preselection gate scripts — rejection

Date: 2026-08-09

## Rejected audit

The scope audit inferred `scripts/check-mvp-delivery-lock.ps1` and `scripts/check-mvp-pre-ticket-selection-robustness.ps1`. Neither path exists, making the combined ripgrep command non-qualifying.

## Permanent correction

Enumerate `scripts` with `rg --files`, select only exact returned gate owners, and bind all subsequent reads and invocations to those paths.
