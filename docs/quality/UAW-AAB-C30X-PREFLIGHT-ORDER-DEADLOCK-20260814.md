# C30X successor AAB preflight-order deadlock

Date: 2026-08-14
Incident: `REG-20260814-2162-AAB-C30X-PREFLIGHT-ORDER-DEADLOCK`
State: registered before repair or retry

## Finding

The C30X `build` phase and visible founder launcher require
`sourceQualification.releasePreflightPassed` before they call the generic
single-AAB wrapper. The wrapper is itself the only owner that generates the
fresh release `--config-only` and merged-manifest evidence. It intentionally
runs those preflights after the phase gate and before consuming the single
build authority.

The resulting dependency is circular: the wrapper cannot start until its own
preflight result already exists. No build was attempted and no authority was
consumed while identifying this defect.

## Required bounded repair

- Create an exact C30X corrective ticket before mutation.
- Keep source/static release-control qualification separate from
  current-invocation generated preflight evidence.
- Require a current sealed source manifest and two identical full regression
  cycles before the wrapper can start.
- Keep the wrapper's config-only and merged-manifest checks before its single
  build-authority consumption point.
- Extend the cross-host/static checks so this ordering cannot regress.
- Preserve failed r60.47 and all current build/upload/install counts.

No runtime, backend, Hosting, provider, Play, device or secret mutation is
authorized by this incident record.

## Resolution

FIX2 now distinguishes `sourceReleaseControlsPassed` from the wrapper-owned
`releasePreflightPassed` result. The launcher and C30X build phase require the
former. The wrapper sets the latter only after fresh config-only and merged-
manifest checks, then consumes the one build authority before the appbundle
command. The order contract passes on PowerShell 7 and Windows PowerShell.
