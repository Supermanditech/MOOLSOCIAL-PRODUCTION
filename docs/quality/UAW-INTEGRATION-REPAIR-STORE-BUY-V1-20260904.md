# Store-Live and Buy conflict-qualified integration repair

Ticket: `UAW-INTEGRATION-REPAIR-STORE-BUY-V1-20260904`

Work ID: `store-buy-conflict-repair-v1-20260904`

State: founder-authorized, fail-closed.

## Customer outcome

Preserve the founder-approved Store-Live workspace and Cursor Buy experience in one regression-safe integration input without changing either product implementation.

## Locked parents

- First parent: Store-Live `aa335eb1497d77c859e7d34b549716350612c5c8`
- Second parent: Cursor Buy `fd55d1cfffa5ed10f753f2ed24461ef9ac6a9a5d`

Both feature branches must remain clean and remote-equal at these exact commits.

## Exact conflict scope

Only these three automatically conflicted coordination owners may be resolved:

- `config/codex-development-regression-registry.json`
- `config/codex-subagent-coordination-policy.json`
- `scripts/check-codex-subagent-coordination-policy.ps1`

No Work, Store, Buy, Chat, Profile, Care, platform, backend or test source may be manually edited by this repair.

## Required preservation

- Preserve all Store and Buy registry prevention content with unique full IDs and numeric prefixes.
- Preserve Cursor COD behavior and Purchase Order context unchanged.
- Preserve the exact UAT-BUY-073 generated metadata blobs.
- Preserve `BuyV2ChatRouteAdapter.productLink` unchanged.
- Keep shared Chat consumption and canonical Care/Medicine ownership for later tickets.

## Stop conditions

Stop without committing if merge-tree reports any conflict outside the three listed owners, either feature remote moves, an accepted commit is missing, generated metadata changes, a product or test owner requires manual repair, or a required regression fails.

## Qualification state

Pre-merge and post-merge qualification results will be appended only after their commands complete successfully. No APK or device action belongs to this ticket.

## Pre-merge qualification

- Bootstrap commit: `c9be1e2f8a8774de2f2df02225270609b76b5696`
- Regression memory: passed with 4,396 unique entries.
- Repair coordination fixture: passed.
- Coordination bootstrap and task-start phases: passed.
- Store-Live remote readback: `aa335eb1497d77c859e7d34b549716350612c5c8`.
- Cursor Buy remote readback: `fd55d1cfffa5ed10f753f2ed24461ef9ac6a9a5d`.
- Merge-tree result: exactly the three declared coordination conflicts; no product-source or test conflict.
- UAT-BUY-073 metadata, COD, Purchase Order and `productLink` remain automatic-merge owners and must not be manually edited.
