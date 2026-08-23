# C30R optional Firebase-config filename search nonzero composition rejection

Date: 2026-08-12

A read-only local diagnosis combined useful Gradle/source matches, an explicit
`google-services.json` absence result and a final optional `rg --files` filter
in one command. The optional filename filter correctly found no matching file
but returned exit code 1, causing the overall tool call to be reported as
failed after the useful bounded findings had already printed.

No file, build, device, Play, provider or runtime state changed. The proven
findings remain: the Android app plugin block does not apply Google Services or
Firebase Crashlytics plugins, settings declares neither plugin, and
`apps/mobile/android/app/google-services.json` is absent.

Prevention: run optional zero-match inventories separately and convert their
expected no-match status into explicit boolean output; do not append them as
the final status owner of a multi-finding diagnosis command.
