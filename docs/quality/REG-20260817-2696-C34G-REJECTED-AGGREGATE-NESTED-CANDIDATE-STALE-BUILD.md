# REG2696 — rejected C34G aggregate retained predecessor build fields

## Outcome

C34G remains rejected and non-reusable. Its authoritative action counts and rejection evidence remain `0/0/0/0`, but the aggregate's nested candidate block contains a stale predecessor build count and AAB hash. No C34G build, upload, install, device action or authority is inferred from those stale fields.

## Prevention

C34H is initialized with explicit zero/null artifact fields. Its gate independently checks every redundant count and artifact mirror before seal and after lifecycle transitions. Rejected C34G is preserved as evidence and is not repaired.
