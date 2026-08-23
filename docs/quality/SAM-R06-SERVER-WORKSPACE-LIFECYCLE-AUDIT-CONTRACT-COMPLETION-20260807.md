# SAM-R06 workspace lifecycle/audit contract completion

Date: 7 August 2026
State: `LOCALLY_COMPLETE_NO_ENVIRONMENT_OR_DEVICE_ACTION_REQUIRED`

SAM-R06 adds one shared immutable workspace request lifecycle with exact
pending, approved, rejected, suspended, resumed, expired and revoked rules.
It enforces tenant/workspace binding, separate reviewer/operator scopes,
expected aggregate version, canonical time, bounded reasons, terminal states
and exact expiry. Each transition appends one attributable payload-free audit
event without mutating the previous aggregate.

Qualification passed: strict focused TypeScript; 15/15 focused tests twice;
complete backend TypeScript; 364/364 full backend tests twice; MVP scope,
delivery discipline and regression-memory gates. Retained TAP is in the SAM-R06
ticket evidence directory.

No UI, route, store, Firebase/API endpoint, live role/data, capability grant,
APK/build/install, OPPO mutation or external action occurred. SAM-R07 retains
separate command idempotency/receipt ownership. OPPO r60.8 remains unchanged.
