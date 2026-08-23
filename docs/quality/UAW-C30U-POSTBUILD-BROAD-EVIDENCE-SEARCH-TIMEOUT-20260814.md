# C30U postbuild broad evidence-search timeout

Date: 2026-08-14
Ticket: `UAW-C30U-POST-R60-45-SOCIAL-REPAIRS-PLAY-INTERNAL-ACCEPTANCE`

## Incident

After the one authorized r60.46 AAB succeeded, a read-only `rg` query searched `config`, `docs`, `artifacts`, and `scripts` together for upload-state evidence. The query exceeded its execution timeout. It did not mutate the repository, AAB, Play Console, or OPPO.

## Resolution

The retry boundary is narrowed to the exact owners already established for this transition:

- `config/play-internal-aab-regression-gate-state-c30u.json`
- `scripts/check-play-internal-aab-regression-gate-state-c30u.ps1`

Historical artifact trees and unrelated ticket generations must not be swept during the sealed postbuild upload transition.
