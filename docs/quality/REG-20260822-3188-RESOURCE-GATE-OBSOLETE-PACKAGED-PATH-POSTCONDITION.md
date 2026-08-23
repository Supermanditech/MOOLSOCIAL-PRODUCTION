# REG3188 - Resource gate obsolete packaged-path postcondition

## Classification

Registered post-preflight gate false rejection after an authoritative successful
release resource link, with zero APK, install or device action.

## Evidence

Forced `:app:processReleaseResources --rerun-tasks --no-daemon` completed
successfully in 1 minute 10 seconds with 168 executed tasks, including
`mergeReleaseResources` and `processReleaseResources`. The gate had already
found the compiled launch-background resource in the release merge output. It
then rejected because it required one exact raw base path under
`packaged_res`, which is not a stable Android Gradle Plugin postcondition after
qualified owners are restored.

## Prevention

Treat native task exit zero plus the exact compiled release merge resource as
the authoritative link proof. If packaged output is checked, enumerate only
bounded launch-background files and accept qualifier-specific placement;
never require one obsolete raw directory layout.
