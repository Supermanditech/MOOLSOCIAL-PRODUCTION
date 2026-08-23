# UAW C33F Windows rg wildcard gate-path recurrence

Date: 2026-08-15
Regression: `REG-20260815-2369-C33F-WINDOWS-RG-WILDCARD-GATE-PATH-RECURRENCE`

A read-only gate discovery correctly found `check-c30x-fix2-preflight-order-contract.ps1` and `check-play-internal-aab-build-wrapper-c30v.ps1`, then passed `scripts/check-c30v*.ps1` and `scripts/check-c30x*.ps1` as `rg` path arguments. On Windows those wildcard path arguments were not expanded, so the follow-up search exited 1. This repeats an already registered Windows `rg` wildcard-path class. No source, manifest, release, device, provider or external state changed.

Recovery: register before retry. Use only the two explicit filenames returned by `rg --files`; wildcard matching is permitted only in the preceding file-list filter, never as a Windows `rg` path argument.
