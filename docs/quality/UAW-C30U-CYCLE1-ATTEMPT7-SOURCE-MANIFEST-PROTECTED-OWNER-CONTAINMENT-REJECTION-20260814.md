# UAW C30U cycle 1 attempt 7 source-manifest protected-owner containment rejection

Date: 2026-08-14

Ticket: UAW-C30U post-r60.45 Social repairs and Play Internal acceptance

## Incident

C30U cycle 1 attempt 7 passed the preceding captured software gates, live
revision checks and exact OPPO predecessor checks. It then generated its source
manifest and failed closed because the qualifier reported that protected source
owners were unexpectedly missing.

No cycle seal was created. No AAB was built or uploaded, and no Play release or
OPPO mutation occurred.

## Preservation rule

Any generated canonical manifest is failed-attempt evidence and must remain
byte-for-byte preserved. Do not delete, overwrite or silently promote it. Read
only the bounded attempt-7 log and exact manifest scalar facts, reconcile
membership against the 206-file protected successor, and redesign the qualifier
to use provisional attempt evidence if another full cycle is required.

## Exact evidence

- Source-manifest log bytes: 271
- Source-manifest log SHA-256:
  `232300CC7CA5D5C2E4C45207325C40E088C47C1E48B166C5C9F07DB0A0FEA868`
- Failed provisional manifest rows: 1,095
- Failed provisional manifest bytes: 142,594
- Failed provisional manifest SHA-256:
  `E0036DC9E68CDF6ECE593ABEEB45BC55897F01389BB9F6D63557B7FD058798FF`
- Current protected Social owners: 206
- Protected owners omitted from the failed manifest: 46

The 46 omissions comprise one Social prototype asset, five iOS/package files,
one supervised test-driver owner and 39 protected PNG goldens. The protected
tree itself still passes unchanged; only the aggregate source manifest omitted
those owners.

## Repair contract

The builder must union the exact protected inventory into the aggregate source
set, assert `protectedSourceOwners=206` and
`missingProtectedSourceOwners=0`, and emit those facts in its counted summary.
The qualifier must validate that exact summary instead of using the total-row
proxy `>1109`. A future cycle writes attempt-specific provisional evidence and
promotes a new accepted-v2 path only after every postcondition passes. The
attempt-7 file remains unchanged at its existing path.

## Repair verification

The repaired builder unions the exact protected inventory, and the qualifier
uses attempt-specific provisional output plus validated accepted-v2 promotion.
The immutable OutputPath/ComparePath preflight owner is:

`artifacts/quality/uaw-c30u-post-r60-45-social-repairs-play-internal-acceptance-20260813-01/c30u-protected-source-union-compare-preflight-20260814-02.txt`

Both modes pass on the same 1,144-row manifest with all 206 protected owners,
zero missing owners and SHA-256:

`90FF7C1D969B31A530D01AD9A093783A73C9CB3ED84E302735DC9AA26DABD37E`

This diagnostic manifest is not the final source seal because this durable
resolution record changes the later cycle fingerprint. Cycle 1 must generate
and validate a new provisional manifest before accepted-v2 promotion.
