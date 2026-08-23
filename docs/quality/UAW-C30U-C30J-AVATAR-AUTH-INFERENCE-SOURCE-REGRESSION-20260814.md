# C30U C30J avatar authorization-inference source regression

Date: 2026-08-14

Ticket: `UAW-C30U-POST-R60-45-SOCIAL-REPAIRS-PLAY-INTERNAL-ACCEPTANCE`

## Failure identity

The bounded authoritative JSON diagnostic reproduced a second authored
failure:

`C30J source never infers YouTube authorization from an avatar`

Owner URL:
`apps/mobile/test/ui_v2/social/uaw_personal_mvp_social_youtube_account_state_journey_c30j_test.dart`

The exact assertion text and matched source token have not yet been diagnosed.
No test weakening or product mutation is authorized from the test title alone.

## Required invariant

A public avatar, cached identity image or visible account decoration must never
grant or imply YouTube authorization, MoolSocial authentication or channel
ownership. C30U's explanation dialog must retain that fail-closed invariant.

## Prevention

Read the exact bounded C30J source-shape assertion and its production owner,
then run this named test independently. If explanation copy or local variable
naming creates a false lexical match, repair it without weakening the semantic
ban; if runtime authorization is inferred, repair the production state owner
and add a negative behavior assertion.

## Release effect

No C30U source manifest or cycle seal exists. C30U build/upload/install counts
remain `0/0/0`; no C30U AAB, upload, Play activation or OPPO mutation occurred.

## Root cause and repair

The source gate hardcoded the prior synchronous signature
`void _openYouTubeChannelStatus()`. C30U correctly made the owner async to await
the explanation dialog. The test now locates the exact async method region and
checks its retained fail-closed purpose, return route, signed-in navigation and
callback separation. The header still forbids `CircleAvatar` and the
MoolSocial-account tooltip, so avatar-derived YouTube authorization remains
prohibited.

The exact named source test passes with one authored test and no failure.
