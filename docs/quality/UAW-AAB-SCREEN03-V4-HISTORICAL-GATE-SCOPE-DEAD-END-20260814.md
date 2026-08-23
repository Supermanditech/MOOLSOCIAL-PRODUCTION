# Screen03 v4 historical-gate scope dead end

Date: 2026-08-14
Incident: `REG-20260814-2166-AAB-SCREEN03-V4-HISTORICAL-GATE-SCOPE-DEAD-END`
State: registered before mutation or qualification retry

The Screen03 v4 production-acceptance gate correctly validates the immutable
v4 package, but its scope assertion accepts only the completed FIX1 ticket and
requires FIX1 reference-write authority. C30X must replay this gate after FIX1
is complete with reference writes false. The current coupling makes that
release regression impossible to execute under its successor scope.

The repair must be an exact ticket. It may add only a read-only, explicitly
named C30X successor replay context; it must retain the original FIX1 creation
context and keep runtime, backend, build, device, external-service and secret
authorities false. It may not change approved v4 bytes or weaken the global UI
lock.

`source-manifest-c30x-provisional-attempt-01.txt` is preserved as superseded;
no accepted C30X source manifest has been sealed.

## Resolution

FIX4 preserves the exact FIX1 creation context and adds only the exact FIX4
and C30X read-only replay contexts. Reference-write authority is required for
FIX1 and forbidden for both replay contexts; every runtime, backend, build,
device, external-service and secret authority remains false. The v4 gate passes
on both PowerShell hosts under C30X, and the global UI lock remains green.
