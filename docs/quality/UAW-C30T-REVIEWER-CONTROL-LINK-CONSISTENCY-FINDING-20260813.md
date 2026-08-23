# C30T reviewer-control link consistency finding

Date: 2026-08-13

## Finding

The Android read-only YouTube connection surface already exposed four explicit user controls: MoolSocial privacy, MoolSocial disconnect help, Google Account permissions, and MoolSocial account deletion. The corresponding public privacy, disconnect, deletion and support pages existed locally, but four links still used the older `security.google.com/settings/security/permissions` destination while Android used `myaccount.google.com/permissions`.

Google Account Help currently directs users to review and remove third-party access from Google Account linked-app controls: <https://support.google.com/accounts/answer/13533235?hl=en>.

## Bounded correction

- Retained all MoolSocial-owned control routes and their existing user-facing scope.
- Aligned the four public pages to `https://myaccount.google.com/permissions`.
- Changed the three stale “Google Security settings” labels to “Google Account permissions”.
- Added Flutter tap coverage for all four Android destinations and static website coverage for all four public pages.

No OAuth scope, provider, Hosting deployment, AAB, upload, install, email or quota state changed.
