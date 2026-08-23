# C30S false native Firebase Data Connect artifact requirement

Date: 2026-08-13

The successful Android release dependency report contains App Check Play
Integrity, Auth, Common and Crashlytics but no Maven artifact named
`firebase-dataconnect`. The Flutter Data Connect package is a direct Dart
dependency and does not add that assumed Android artifact.

The gate proves Data Connect through pubspec/lock and affected Flutter tests.
Only actual native Firebase families are required in
`releaseRuntimeClasspath`; exact unused native SDKs remain forbidden.
