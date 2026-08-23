# REG3189 - Redundant v21 restoration conflated incremental state

## Classification

Registered authoritative lint audit correction with zero lint errors, zero new
APK, zero install and zero device action.

## Evidence

Release lint completed successfully across 604 executed tasks. Its XML report
contains zero errors and two warnings: the known merged Meta
`fb_login_protocol_scheme` warning, plus `ObsoleteSdkInt` proving
`drawable-v21` is unnecessary because the app minimum SDK is 24. The base
`drawable/launch_background.xml` is valid and sufficient. Forced release
resource processing succeeded only after stale incremental merge state was
recomputed; restoring the v21 duplicate was not the essential fix.

## Prevention

Preserve the pre-existing intentional deletion of the obsolete v21 duplicate.
Require the base launch owner, validate the min-SDK boundary, permit only that
exact obsolete tracked deletion, and force `processReleaseResources` with
`--rerun-tasks` before APK assembly. Do not add redundant qualifier resources
to mask stale build intermediates.
