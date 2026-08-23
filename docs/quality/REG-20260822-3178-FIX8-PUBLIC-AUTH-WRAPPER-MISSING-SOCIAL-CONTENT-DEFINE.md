# REG3178 - FIX8 PublicAuth wrapper missing Social content define

## Classification

Registered authoritative prebuild-gate rejection with zero Flutter, APK or install action.

## Evidence

The founder's first authorized r60.81 wrapper invocation passed MVP and motion
gates, then stopped at the APK runtime-name allowlist. Name-only comparison
proved one difference: the FIX8 candidate identity activates the exact Dev
Social-content endpoint requirement, while `Get-PublicAuthSideloadRuntimeValues`
did not add `MOOLSOCIAL_SOCIAL_CONTENT_URL`. No private value was read or
printed, and Flutter was never invoked.

## Prevention

Add the exact non-secret Dev Social-content URL to the PublicAuth profile,
assert it in the sideload-control test, invalidate the `...20260822-02` seal,
and create a distinct live-owner `...20260822-03` manifest before one retry.
