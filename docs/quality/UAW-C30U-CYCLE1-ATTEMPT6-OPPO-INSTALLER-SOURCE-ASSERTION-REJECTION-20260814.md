# UAW C30U cycle 1 attempt 6 OPPO installer-source assertion rejection

Date: 2026-08-14

Ticket: UAW-C30U post-r60.45 Social repairs and Play Internal acceptance

## Incident

C30U cycle 1 attempt 6 passed the captured format, analyzer, authoritative
Flutter, backend, Hosting, release configuration and ticket gates. It also
accepted the sole connected OPPO and installed r60.45 identity, then failed
closed because its `cmd package get-install-source` assertion did not find
`com.android.vending`.

The accepted source manifest and cycle-1 seal were not created. Build, upload
and install counts remain zero.

## Exact diagnosis

`adb devices` returns exit 0 with the exact `2b3e0f71 device` row. The bounded
installer command returns exit 255 and exactly:

`Unknown command: get-install-source`

This OPPO package-service implementation does not support that subcommand. The
qualifier must use a supported exact-package installer listing and still
require the literal Google Play installer identity; it may not drop or weaken
the invariant.

The immutable bounded diagnostic is:

`artifacts/quality/uaw-c30u-post-r60-45-social-repairs-play-internal-acceptance-20260813-01/cycle1-attempt-6-oppo-installer-source-diagnostic.log`

SHA-256:

`E4A132FAEE60164E326D08627314B8D484563F1CA0F1331428A3DFAF6E695DFC`

The supported `pm list packages -i com.moolsocial.app` read returns native exit
0 and exactly one anchored target row with
`installer=com.android.vending`. The C30U qualifier now captures that native
exit immediately and requires exactly one anchored target Play row. The AAB
state gate statically rejects reintroduction of the unsupported command.

Never uninstall, clear data, downgrade, sideload, ADB-install or perform another
Play update to force this assertion to pass.
