# Global Mool navigation C04 completion

Ticket: `UAW-PERSONAL-MVP-GLOBAL-MOOL-BOTTOM-RAIL-NAVIGATION-FIX1-C04-BUY-RAIL-BACK`
State: `COMPLETE_RUNTIME_TESTS_NO_BUILD_NO_DEVICE_MUTATION_WITH_PREEXISTING_SCREEN01_LOCK_BLOCKER`

C04 removed Buy's local main-action popup. The persistent Buy rail now always
contains Mool, Shop, Wholesale, Medicine, Orders and Chat. Mool pushes the
existing stable Personal hub through the same production-router callback on
all eleven Buy route variants. Back from the hub restores the exact Buy
destination and nested view, including Medicine and Account, without replacing
the singleton Buy session.

Buy root Back now closes search and internal Buy depth first, pops exact route
history when present, and otherwise falls back to the stable Mool hub. Invalid
return requests are ignored. The obsolete Buy-to-Social `openMool` fallback and
its persisted Social alias were removed.

The fix reuses `BuyV2Screen`, `BuyV2Session`, the existing Personal hub,
`/app/buy`, `/app/mool`, GoRouter history and the established Buy state owners.
No new screen, named route, session, service, backend, provider, transaction,
payment, persistent product state, accepted reference or golden was created.

## Verification

- focused Buy/Mool/root matrix: 92 tests, two clean cycles;
- complete discovered Buy V2 directory: 360 tests, two clean cycles, with 20
  explicitly skipped candidate-capture tests retained unchanged in each run;
- complete seven-file connected production-router journey set: 79 tests, two
  clean cycles;
- exact production cases: repeated Mool -> Buy -> Back, Medicine -> Mool ->
  Back, Account -> Mool -> Back, invalid Eat return -> Mool, and internal
  search/account Back ordering, clean;
- all eleven production `BuyV2Screen` router variants provide the same Mool
  callback; zero Buy main-action popup owners and zero Buy Social fallback
  strings remain;
- affected-file `dart format`: six files, zero final changes;
- affected-file `flutter analyze`: six files, no issues;
- structural global contract: clean; the implementation boundary now rejects
  exactly the queued C05 shared Mool Social alias;
- Personal action projection and its six negative self-tests: clean;
- MVP scope, delivery-discipline and permanent regression-memory gates: clean;
- affected tracked `git diff --check`: clean.

Primary evidence directory:
`artifacts/quality/uaw-personal-mvp-global-mool-bottom-rail-navigation-fix1-c04-20260806-01`.

Every C04 mistake or false attribution was registered before retry as
`REG-20260806-042` through `REG-20260806-046`; original failure evidence is
preserved. These entries permanently gate PowerShell excerpt shape, Buy test
initial-state setup, deleted palette keys, pre/post approved-lock baselines,
independent final-gate reporting and evidence-path existence checks.

## Pre-existing protected-lock blocker

`check-approved-ui-locks.ps1` rejects the clean-at-HEAD Screen 01 source. The
immutable lock expects SHA-256
`b0e7b099b70be7240a4e7699596ab7f16b77285fba9c23c4f3708afda7ae218d`,
while the unchanged worktree/HEAD file has
`d08dba928b884554984d28891f5e465b1f7fa910d3884ebe49b6466d199147be`.
The file has no worktree diff and predates this continuation. C04 did not touch
Screen 01 or any accepted reference. This remains a separate release/build
blocker and must not be "fixed" by mutating the accepted screen.

## Boundary

C04 did not implement Chat/shared runtime changes. It did not build an APK,
install, uninstall, clear device data, mutate OPPO, access credentials, contact
a live provider, send a message or call, move funds, write Production, commit,
push, deploy, promote, change the screenbook or alter preserved rejection
evidence. Device qualification remains reserved for cumulative C06.
