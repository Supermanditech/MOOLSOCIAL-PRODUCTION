# REG2849 — C34L transition FIX2 session-ID phone false positive

Date: 17 August 2026
State: registered second PS7 lifecycle fixture rejection; zero external action

## Mistake

The second direct PS7 lifecycle run reached Play evidence validation but the
privacy scanner rejected sanitized session ID `c34l-play-session-00000001` as
phone-shaped because of its eight trailing digits. Cleanup completed; no retry,
later mutation, external, private, or device action followed.

## Prevention

Validate `sessionId` against its exact approved public grammar first, then exempt
only that schema position from generic phone scanning. Retain phone rejection
for unknown/private/contact fields and add a valid digit-bearing session fixture.
