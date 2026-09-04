# Store-Live, Universal accessibility and Buy replacement repair

Ticket: `UAW-INTEGRATION-REPAIR-STORE-BUY-V2-20260904`

Work ID: `store-buy-conflict-repair-v2-20260904`

State: founder-authorized, fail-closed.

## Locked parents

- Corrected Store-descended first parent: `300f4247165a097d82624f4b40c9c2d611c7bc48`
- Unchanged Cursor Buy second parent: `fd55d1cfffa5ed10f753f2ed24461ef9ac6a9a5d`

## Exact manual conflict scope

- `config/codex-development-regression-registry.json`
- `config/codex-subagent-coordination-policy.json`
- `scripts/check-codex-subagent-coordination-policy.ps1`

No automatically merged product or test owner may be manually changed.

## Required preservation

- Preserve the corrected Universal design/test blobs from `300f4247…`.
- Preserve every Cursor Buy blob, UAT-BUY-073 generated metadata, COD eligibility, contextual Purchase Order, scanner and `productLink`.
- Preserve failed repair `c48e4ecc…` and diagnostic evidence `58af65f0…` as non-input evidence.
- Stop on any unexpected source/test conflict.

## Qualification

Pre-merge and post-merge gate results will be appended only after completion. No APK, device, deployment or private-account action belongs to this repair.
