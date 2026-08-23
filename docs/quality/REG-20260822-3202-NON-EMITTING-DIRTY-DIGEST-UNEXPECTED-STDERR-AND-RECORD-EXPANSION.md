# REG-20260822-3202 — Non-emitting dirty digest unexpected stderr and record expansion

## Incident

The first post-resource-link non-emitting `git status` digest completed with
exit zero but returned non-empty stderr and a large unexpected record-count
expansion. Its digest was not accepted as authoritative.

## Impact

- Fresh build authorization consumed: `false`
- APK builds: `0`
- OPPO actions: `0`
- Private/provider actions: `0`
- Files cleaned or deleted: `0`

## Root cause

The raw status capture did not separately classify stderr or distinguish
repository evidence from newly materialized Gradle intermediates before
reporting a single digest result.

## Permanent prevention

Register any non-empty stderr or abrupt dirty-record expansion before retry.
Classify counts without emitting paths or credential values, preserve all
files, and accept a digest only with exit zero and empty stderr.
