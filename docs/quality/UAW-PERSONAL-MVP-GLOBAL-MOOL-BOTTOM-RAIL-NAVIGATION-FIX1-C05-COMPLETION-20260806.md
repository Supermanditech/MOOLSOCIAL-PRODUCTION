# Global Mool navigation C05 completion

Ticket: `UAW-PERSONAL-MVP-GLOBAL-MOOL-BOTTOM-RAIL-NAVIGATION-FIX1-C05-CHAT-SHARED-RETURN`
State: `COMPLETE_RUNTIME_TESTS_NO_BUILD_NO_DEVICE_MUTATION_WITH_PREEXISTING_SCREEN01_LOCK_BLOCKER`

C05 replaced the Chat inbox, Chat thread composer and Shared dock Mool route
replacements with pushes to the existing stable Personal hub. Android system
Back from the hub now restores the exact mounted Chat or Shared owner. Filtered
inbox search/filter state, unsent thread text, reply and attachment state, and
all Shared session filters remain unchanged. Shared Mool no longer aliases
Social.

The fix reuses `ChatInboxScreen`, `ChatThreadScreen`, their mounted text
controllers, `ChatSession`, `SharedHubScreen`, `_SharedDock`, `SharedSession`,
`PersonalMoolRootV2`, `/app/mool` and GoRouter push/pop history. No new screen,
named route, session, service, store, backend, provider, draft persistence or
persistent product state was created.

## Verification

- focused C05 production-router matrix: 10 tests, two clean cycles;
- complete Chat and Shared behavioral suites: 26 tests, two clean cycles;
- complete Personal/universal directory: 177 tests, two clean cycles;
- complete eight-file connected production-router journey set: 99 tests, two
  clean cycles;
- exact cases: filtered inbox search -> Mool -> system Back, thread unsent
  text/reply/attachment -> Mool -> system Back, and Shared screens 157, 158,
  159, 160, 161, 162 and 165 -> Mool -> system Back, clean;
- affected-file `dart format`: four files, zero final changes;
- affected-file `flutter analyze`: four files, no issues;
- global 22-case implementation contract: fully clean with all C01-C05
  blockers removed;
- Personal action projection and its six negative self-tests: clean;
- MVP scope, delivery-discipline and permanent regression-memory gates: clean;
- PowerShell gate syntax, scope JSON parsing and affected tracked
  `git diff --check`: clean.

Primary evidence directory:
`artifacts/quality/uaw-personal-mvp-global-mool-bottom-rail-navigation-fix1-c05-20260806-01`.

The one C05-authored static-test defect was caught before execution and
registered as `REG-20260806-047`: stable interaction keys may not be deleted
when only an obsolete callback is being removed.

## Pre-existing protected-lock blocker

The REG-045 Screen 01 lock mismatch was captured before and after C05. The lock
still expects
`b0e7b099b70be7240a4e7699596ab7f16b77285fba9c23c4f3708afda7ae218d`,
while the clean-at-HEAD file remains
`d08dba928b884554984d28891f5e465b1f7fa910d3884ebe49b6466d199147be`.
C05 made zero protected Screen 01 diff and did not mutate the accepted screen,
lock, manifest or reference. This remains a separate release/build blocker.

## Boundary

C05 did not change message sending, calls/video, attachments, providers,
account/workspace behavior, backend state, goldens or accepted presentation.
It did not build an APK, install, uninstall, clear device data, mutate OPPO,
access credentials, contact a live provider, send a live message or call, move
funds, write Production, commit, push, deploy, promote, change the screenbook
or alter preserved rejection evidence. Profile provenance, build and real
OPPO qualification remain reserved for C06.
