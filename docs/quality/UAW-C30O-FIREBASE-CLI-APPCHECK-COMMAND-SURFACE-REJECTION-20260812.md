# C30O Firebase CLI App Check command-surface rejection

Date: `2026-08-12`

State: `REJECTED_READ_ONLY_HELP_QUERY_NO_PROVIDER_MUTATION`

The authenticated Firebase CLI session for `hello@moolsocial.com` successfully
listed the active Dev Android app, package `com.moolsocial.app`, and app ID
`1:760290687711:android:4202409fd3ab38f6ce076a`.

A subsequent read-only `firebase help appcheck` query reported that `appcheck`
is not a valid command on the installed CLI. The help process returned zero,
but the diagnostic text is authoritative: this CLI surface cannot inventory or
configure Firebase App Check. No Firebase, Google Play, repository or device
state changed.

Permanent prevention: do not infer or invent Firebase CLI App Check commands.
Use the supported Firebase Console or documented Firebase App Check management
API only after the exact `hello@moolsocial.com` account context is verified.
Never read, output or persist App Check tokens or private attestation verdicts.
