# UAW C33E FIX3 Social auth rollback independent-cleanup qualification

Date: 2026-08-15

Ticket: `UAW-C33E-FIX3-SOCIAL-AUTH-ROLLBACK-INDEPENDENT-CLEANUP`

## Outcome

The existing Firebase Social authentication gateway now attempts Firebase
session cleanup and native Google account-cache cleanup independently. It keeps
the accepted Firebase-then-Google success order, captures the first cleanup
failure, still attempts the second owner, and rethrows the first failure only
after both attempts. Cleanup therefore cannot falsely report success and a
first-leg failure no longer skips the second cleanup owner.

`JourneySession` retains its qualified recovery behavior when account bootstrap
and cleanup both fail: it remains signed out at the sign-in stage, is not busy,
preserves the exact protected Create origin and displays the original retryable
account-bootstrap error rather than replacing it with cleanup diagnostics.

No locked Screen 03 presentation, accepted Screen 03 test, golden, reference,
route, provider, backend, build, Play, OPPO, credential or external-service
owner changed.

## Regression handling

- `REG-20260815-2344`: sequential cleanup escape repaired.
- `REG-20260815-2345`: first test fixture omitted guest-ready mode; the failed
  run was rejected, registered and the complete four-test file was rerun.

## Verification

Two identical post-repair source cycles passed. Each cycle contained:

- formatter no-change result: 2 exact changed/new Dart owners, 0 changes
- whole-mobile analyzer: 0 issues
- focused authentication/action suite: 40 passed, 0 failed
  - FIX3 independent-cleanup tests: 4
  - existing Firebase Social auth gateway tests: 10
  - existing Screen 03 session tests: 11
  - existing C30T Social auth/Feed action tests: 15
- FIX3 static/source/lifecycle gate: passed
- nested C30Z authentication truth gate: passed
- nested C33E FIX2 live-readiness gate: passed at `0/4` qualified live facts
- approved UI locks: passed before and after runtime implementation

Additional host evidence:

- PowerShell 7 FIX3 gate: passed
- Windows PowerShell 5.1 FIX3 gate: passed
- C33E FIX2 behavioral contract: passed on both PowerShell hosts after the
  exact FIX3 successor lifecycle extension
- temporary FIX2 fixture residue: 0

## Bound owners

- runtime gateway SHA-256:
  `456E1E1E2ECA4AAAEF00810495C3961FF74F390C3B6A51EEF2DEF69AB9BAAC48`
- FIX3 behavioral test SHA-256:
  `E83A383DB41C12539270E419FD99F34A3A366D925314BD9F12721548CC511D0C`
- FIX3 gate SHA-256:
  `815F7A2C67EEC5ACBBF7A985B956AF87D9AC3FBDDC3A6808F03A14A4D2000279`
- C30Z lifecycle gate SHA-256:
  `4BA0C3478FAB5DD6E955A7A77A07ED6AF239B0EA3D1067559C5E524F54A7C599`
- C33E FIX2 readiness gate SHA-256:
  `2F93467F7D92BAAB2C216A0DD3D92BCCCE2A2F2DA4B681E6442E5C4EC0FDECB8`
- C33E FIX2 behavioral checker SHA-256:
  `96226C55C0D469D67D4C8CD14976743A9CF05C5D037598DC5314BA06D8F56148`

## Remaining release boundary

This is source qualification only. The installed Play candidate remains failed
`1.0.0-r60.48+2026081348` with build/upload/install counts `1/1/1`, and does
not contain C30Z, FIX2 or FIX3 repairs. The Google live-readiness state remains
blocked with `0/4` facts qualified. A fresh source manifest and complete future
release regression cycles are mandatory after the four sanitized live facts
qualify and before any separately authorized successor AAB.

YouTube quota submission and email remain held until the repaired successor is
Play-installed and complete login, protected Social action, consent and
reviewer-access journeys pass on OPPO.
