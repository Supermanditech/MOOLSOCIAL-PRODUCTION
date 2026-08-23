# SAM-R05 server capability/geography policy contract completion

Date: 7 August 2026
State: `LOCALLY_COMPLETE_NO_ENVIRONMENT_OR_DEVICE_ACTION_REQUIRED`

SAM-R05 adds one shared pure policy owner for exact workspace profile,
capability, category, service area and validity. It returns active, held,
disabled, missing, category mismatch, service-area mismatch, not-yet-effective
or expired truth; rejects overlapping windows and conflicting policy IDs; and
returns deterministic immutable results without local capability inference.

The implementation reuses the existing supply qualifier semantics while
leaving the supply aggregate unchanged. It prevents separate Food, Doctor,
Salon, Ride, Work and commerce adapters from inventing their own geography or
validity logic. It adds no UI, route, persistence, Firebase/API endpoint,
live role/policy data, workspace mutation, APK, build or OPPO action.

Qualification passed: strict focused TypeScript; 17/17 focused tests twice;
complete backend TypeScript; 349/349 complete backend tests twice; MVP scope,
delivery discipline, regression memory and target diff checks. Retained TAP:

- `artifacts/quality/sam-r05-server-capability-geography-policy-contract-20260807-01/02-full-backend-cycle-1.tap`
- `artifacts/quality/sam-r05-server-capability-geography-policy-contract-20260807-01/02-full-backend-cycle-2.tap`

SAM-R05 supplies the policy prerequisite for later exact participant adapters.
It does not activate any capability or close environment, reviewer, provider,
reference, build, device or release gates. OPPO r60.8 remains unchanged.
