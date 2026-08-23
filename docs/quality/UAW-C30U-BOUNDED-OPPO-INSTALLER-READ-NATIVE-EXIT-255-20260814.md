# UAW C30U bounded OPPO installer read native exit 255

Date: 2026-08-14

## Incident

The first bounded read of
`cmd package get-install-source com.moolsocial.app` after cycle-1 attempt 6
returned ADB native exit 255. No installer fields were observed, so the result
does not prove either Play or non-Play installation identity.

## Prevention

Before another package-manager read, capture `adb devices` and its native exit
without a filtering pipeline. Require exactly one `2b3e0f71` state row. If it is
not `device`, stop for founder USB/authorization interaction rather than
looping ADB or mutating the installed app.

## Resolution

The exact OPPO row is ready. Replaying the bounded command returns
`Unknown command: get-install-source`, proving an unsupported OPPO package-
service subcommand rather than a USB or authorization failure. The release gate
must use a supported read-only exact-package installer query with immediate
native-exit capture.

No uninstall, data clear, downgrade, sideload, ADB install, Play update or
release artifact mutation occurred.
