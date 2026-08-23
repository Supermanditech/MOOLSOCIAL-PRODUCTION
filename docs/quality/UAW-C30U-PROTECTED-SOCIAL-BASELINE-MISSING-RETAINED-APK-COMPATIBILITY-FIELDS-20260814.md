# C30U protected Social baseline missing retained-APK compatibility fields

Date: 2026-08-14

Ticket: `UAW-C30U-POST-R60-45-SOCIAL-REPAIRS-PLAY-INTERNAL-ACCEPTANCE`

## Failure

The new C30U successor gate parsed successfully, but its first run stopped in
the generic protected Social gate because the candidate object did not expose
`retainedApk`. The C30U baseline recorded only its future AAB fields.

## Root cause

`check-social-protected-baseline.ps1` uses the presence of a `candidate` object
to select the candidate schema and then reads `retainedApk` and
`retainedApkSha256` under strict mode, even when the values are intentionally
blank pending device acceptance.

## Prevention

Every candidate-schema successor baseline includes both generic retained-APK
compatibility fields as empty strings until an APK is actually owned, while
C30U retains its separate AAB fields. Never change the generic historical gate
or invent an artifact value to bypass a missing property.

## Release effect

The protected runtime tree was not changed by the schema failure. No source
cycle, AAB, upload, Play activation or OPPO mutation occurred; counts remain
`0/0/0`.

## Repair verification

The C30U candidate now retains empty `retainedApk` and
`retainedApkSha256` compatibility fields alongside its empty future AAB fields.
The unchanged generic gate verifies 206 files and the exact portable tree, and
the C30U successor gate passes with OPPO acceptance still pending.
