# MoolSocial store identity

## Final decision

The shared production application identifier is:

- Android application ID and namespace: `com.moolsocial.app`
- iOS bundle identifier: `com.moolsocial.app`
- iOS test bundle identifier: `com.moolsocial.app.RunnerTests`

The Flutter package name remains `moolsocial`; it is a source-code package name
and is separate from the Android and iOS store identifiers.

## Why this identifier is safe to register

On 18 July 2026, the existing Google Play organisation account showed
**Create your first app**. No Play app or Android package name was registered in
that account, so there is no legacy store package that MoolSocial must retain.
The final identifier therefore uses the verified MoolSocial brand domain rather
than the earlier Supermandi development namespace.

## Immutability rule

`com.moolsocial.app` is a release invariant. Do not rename it after creating the
production app in Google Play Console or App Store Connect. Changing an
identifier after store registration creates a different app instead of
upgrading the installed app.

All Firebase Android/iOS registrations, OAuth clients, App Check providers,
deep links, notification credentials, CI signing jobs and store records must
use this exact identifier.

## Registration sequence

1. Keep this identifier committed in the Flutter native shells.
2. Register Android app `com.moolsocial.app` in the production Firebase project.
3. Register iOS app `com.moolsocial.app` in the same production Firebase
   project.
4. Generate environment-specific Firebase configuration through CI or the
   approved local setup; never commit production secrets.
5. Create the Play Console app with `com.moolsocial.app` when the signed Android
   App Bundle is first uploaded.
6. Create the App Store Connect record with `com.moolsocial.app`.
7. Treat any requested identifier change as an architecture decision requiring
   explicit owner approval before either store registration.
