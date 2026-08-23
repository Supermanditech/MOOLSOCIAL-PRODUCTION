# UAW Personal R01-R15 cumulative OPPO qualification founder authorization

Date: 6 August 2026
Candidate: `UAW-PERSONAL-R01-R15-CUMULATIVE-OPPO-QUALIFICATION-FIX1`
State: `FOUNDER_AUTHORIZED_MACHINE_GATED_BUILD_INSTALL_AND_DEVICE_QUALIFICATION`

## Founder direction

The founder explicitly authorized the completed Personal tickets to proceed
through MVP scope and APK machine gates into production-grade OPPO
qualification. The founder emphasized that the existing protected FIX7 APK
behaves well on OPPO and that the successor must retain the same production
discipline.

## Exact authority boundary

This authorization permits:

- registering one cumulative Personal R01-R15 qualification candidate;
- minimum build-gate infrastructure correction needed to support a non-Buy
  UAW candidate without bypassing the existing strict wrapper;
- deterministic analysis and affected/full regression evidence;
- one machine-gated profile APK build;
- signature, package, version, source and APK checksum verification;
- an in-place same-package OPPO upgrade that preserves current app data; and
- bounded device navigation, interruption, accessibility, reduced-motion,
  performance and runtime-failure qualification.

This authorization does not permit:

- manually uninstalling the protected FIX7 app or clearing its OPPO data;
- bypassing a signature, package, version, source or machine-state mismatch;
- deleting or overwriting the protected FIX7 APK/evidence;
- claiming R04 or R16-R45 product functionality as implemented;
- credentials, live provider calls/messages, payments, funds movement or
  Production data writes; or
- commit, push, deployment or promotion.

If Android cannot perform a compatible in-place upgrade, execution stops
before uninstall or data loss. Clean-state validation may use an isolated
local emulator; erasing OPPO state requires a later separate founder decision.

## Founder continuation authorization

After the prebuild interaction gate proved that protected Social still emitted
the two Work paths removed by UAW-R12, the founder directed Codex to continue,
finish the current candidate, proceed to pending tickets and leave the final
founder-review points on OPPO. This authorizes only the already-disclosed
compatibility correction:

- `/app/work/choose` to `/app/work/workspace/choose`; and
- `/app/work/proof` to `/app/work/workspace/proof`.

It does not authorize any other Social visual, copy, state, provider or
baseline change. The protected-Social rejection remains evidence and is not
replaced.
