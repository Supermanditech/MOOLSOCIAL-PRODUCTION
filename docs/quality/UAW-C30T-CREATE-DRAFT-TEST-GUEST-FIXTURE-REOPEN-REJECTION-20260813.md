# UAW C30T Create-draft test guest-fixture reopen rejection — 2026-08-13

## Outcome

The corrected draft-retention test used the visible Feed `Create a post` action,
but its shared `_Owners` fixture had not started an authenticated JourneySession.
The app therefore entered the real sign-in journey and correctly did not remount
the workbench. The expectation that Create would immediately reopen failed.

The test run is rejected. This does not establish an implementation defect.

## Permanent prevention

Create-author tests that cross an authentication-owned CTA must start a ready
JourneySession with an explicitly signed-in test gateway. Do not infer
authentication from a populated email field or from starting directly on a
Create subaction.
