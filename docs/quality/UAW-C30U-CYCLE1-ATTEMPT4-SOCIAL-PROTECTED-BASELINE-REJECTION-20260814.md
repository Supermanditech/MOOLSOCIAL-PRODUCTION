# C30U cycle 1 attempt 4 Social protected-baseline rejection

Date: 2026-08-14

Ticket: `UAW-C30U-POST-R60-45-SOCIAL-REPAIRS-PLAY-INTERNAL-ACCEPTANCE`

## Failure

Cycle 1 attempt 4 passed regression memory, MVP/delivery scope, C30U reconcile,
immutable Screens 01–03, formatting, whole-mobile analysis, the authoritative
405+3 Flutter manifest, backend, Hosting and release config-only checks. It then
failed closed when `scripts/check-social-protected-baseline.ps1` returned exit
`1`.

Retained log:

- Path:
  `artifacts/quality/uaw-c30u-post-r60-45-social-repairs-play-internal-acceptance-20260813-01/cycle1-attempt-4-check-social-protected-baseline.log`
- Bytes: `289`
- SHA-256:
  `0CB5FE76D8F748C884FAC0DF859ED6EF3DC5A5F347073E9C499A62F87E78625C`

## Root cause pending exact bounded log diagnosis

The visible qualifier result identifies the protected-baseline gate only. The
gate log must be read before deciding whether C30U introduced a genuine
protected Social regression or the predecessor gate legitimately rejects an
authorized successor owner/checksum change.

## Prevention

Read the exact 289-byte attempt log, then inspect only the gate's named failed
owner/checksum assertion. Never bypass or reseal a genuine protected mismatch.
If the old gate hard-binds an intentionally superseded current test/source
checksum, create a separate C30U successor containment gate that preserves all
substantive Social protections and update the qualifier only after it passes.

## Release effect

No source manifest or cycle seal exists. C30U build/upload/install counts remain
`0/0/0`; no C30U AAB, upload, Play activation or OPPO mutation occurred.

## Exact diagnosis and successor containment

The retained gate log reports only an inventory-lineage mismatch: the generic
default remains the preserved C25F 178-file seal, while the current authorized
tree has 206 files. The preserved C29E successor has 180 files. This was not a
portable-tree mismatch against a current C30U seal and not a product test
failure.

C30U now owns a separate additive successor seal and gate:

- Baseline:
  `artifacts/quality/social-protected-candidate-c30u-post-r60-45-social-repairs-20260814-01/BASELINE.json`
- Baseline SHA-256:
  `8E6BC23C1FAE8D59DF25E9C37AF0ACD1F74B0CEED5949AEBB8B2846DD2FC73C8`
- Successor gate: `scripts/check-c30u-social-protected-successor.ps1`
- Files: `206`
- Portable tree:
  `f0fa9d67b7fde975d544792d3194dbe457b2028750ee444b02a3c9cd98ef75db`
- Predecessor SHA-256:
  `A4A22EB631522A9F15FB2D8A22EDA98C8F12FDF138A9B31ABA4C4EE25751E810`
- State: `FOUNDER_AUTHORIZED_SUCCESSOR_PENDING_OPPO_ACCEPTANCE`

The successor gate invokes the unchanged generic gate with the exact C30U
baseline and passes. All historical baselines remain unchanged.
