# Global Mool navigation C03 completion

Ticket: `UAW-PERSONAL-MVP-GLOBAL-MOOL-BOTTOM-RAIL-NAVIGATION-FIX1-C03-SOCIAL-RAIL-BACK`
State: `COMPLETE_RUNTIME_TESTS_NO_BUILD_NO_DEVICE_MUTATION`

C03 removed Social's local Mool main-action mode. The Social bottom rail now
contains only Shorts, Videos, Feed and Create plus the global Mool and Chat
controls. Mool pushes the existing stable Personal hub; header and Android
system Back from that hub use one explicit return contract and restore the
exact Social sub-action. Social Back closes active video depth before route
history and never opens a menu.

The fix reuses `SocialUniversalV2`, `Screen04CapabilityRail`, the existing
Personal hub, `/app/social`, `/app/mool`, GoRouter history and the established
Social state owners. No new screen, named route, session, service, backend,
provider, persistent product state, accepted reference or golden was created.

## Verification

- focused C03/navigation set: 43 tests, two clean cycles;
- complete Personal/universal directory: 167 tests, two clean cycles;
- complete seven-file production-router journey set: 79 tests, two clean
  cycles;
- protected Social provider/runtime pack: 22 tests, two clean cycles;
- exact chained regression: active Social video -> system Back -> Mool hub ->
  system Back -> exact Videos state, clean;
- affected-file `dart format`: 10 files, zero final changes;
- affected-file `flutter analyze`: 10 files, no issues;
- structural global contract: clean; the implementation boundary now rejects
  exactly the queued Buy rail, Buy Social fallback and shared Mool alias;
- MVP scope, delivery-discipline and permanent regression-memory gates: clean;
- affected tracked `git diff --check`: clean.

Primary evidence directory:
`artifacts/quality/uaw-personal-mvp-global-mool-bottom-rail-navigation-fix1-c03-20260806-01`.

Every C03 mistake, false diagnostic, failed hypothesis or tooling recurrence
was registered before retry as `REG-20260806-026` through
`REG-20260806-041`; original failure evidence is preserved. In particular,
`REG-20260806-033` permanently gates the video-Back-Mool-Back sequence and
requires the stable hub to own system Back through the same callback as header
Back.

## Boundary

C03 did not implement Buy, Chat or shared runtime changes. It did not build an
APK, install, uninstall, clear device data, mutate OPPO, access credentials,
contact a live provider, send a message or call, move funds, write Production,
commit, push, deploy, promote, change the screenbook or alter the preserved
r60.6 rejection evidence. Device qualification remains reserved for cumulative
C06.
