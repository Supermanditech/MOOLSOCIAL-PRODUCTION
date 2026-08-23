# SAM-R07 idempotent privileged command protocol completion

Date: 7 August 2026
State: `LOCALLY_COMPLETE_NO_ENVIRONMENT_OR_DEVICE_ACTION_REQUIRED`

SAM-R07 adds one pure shared privileged-command envelope, authorization,
reservation and completion-receipt owner. It requires tenant binding, exact
scope, explicit confirmation, bounded reason, canonical time and expected
version before a new reservation. JSON-safe payloads are canonicalized,
bounded and rejected when they contain sensitive keys. SHA-256 fingerprints
make exact retries return the prior immutable receipt and reject changed actor,
scope, version, reason or payload under the same command ID.

Qualification passed: strict focused TypeScript; 16/16 focused tests twice;
complete backend TypeScript; 380/380 full backend tests twice; MVP scope,
delivery discipline and regression-memory gates. Full TAP logs and compiled
test evidence are retained in the SAM-R07 evidence directory.

No command was executed. No UI, route, persistence, Firebase/API endpoint,
live role/data, money/provider action, APK/build/install, OPPO mutation or
external system changed. OPPO r60.8 remains the preserved founder-review APK.
