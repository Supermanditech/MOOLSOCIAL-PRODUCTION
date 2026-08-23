# SAM-R01 server stable workspace membership read contract completion

Date: 7 August 2026
State: `LOCALLY_COMPLETE_NO_ENVIRONMENT_OR_DEVICE_ACTION_REQUIRED`

SAM-R01 adds one pure server-domain owner for projecting a Personal account's
active workspace memberships from stable server IDs. It validates identifiers,
canonical timestamps, aggregate version and validity intervals; rejects
cross-account records, conflicting membership identities and simultaneous
active grants for one workspace; excludes pending, revoked, expired and
out-of-window state; preserves an unknown registered profile ID without
inventing capabilities; sorts deterministically; and returns deeply frozen
safe projections without mutating input.

The implementation deliberately adds no UI, screen, route, persistence store,
Firestore rule, callable endpoint, session claim, workspace creation,
capability grant, APK, build, install, provider action or Production access.
The existing supply-participant aggregate remains unchanged and supplies the
reused identifier, tenant, immutability, versioning and fail-closed design
patterns without becoming the wrong membership owner.

## Qualification

- Focused strict TypeScript: passed.
- Focused membership tests: 15/15 passed twice.
- Complete backend TypeScript: passed.
- Complete backend regression: 332/332 passed twice.
- MVP scope and 60–75-day delivery discipline: passed.
- Permanent regression memory: passed at 84 registered entries.
- Target diff check: passed.

Full retained TAP evidence:

- `artifacts/quality/sam-r01-server-stable-workspace-membership-read-contract-20260807-01/05-full-backend-cycle-1.tap`
  (`5E2ED149CB7F18D86470741B88638B25120DF193DFD724166B0CE2F4A28B59D5`)
- `artifacts/quality/sam-r01-server-stable-workspace-membership-read-contract-20260807-01/06-full-backend-cycle-2.tap`
  (`F66685B8C075667702AD5D8CF3B1042EDC9D4D5BAB78BF5A8AB7F0AEB7745314`)

OPPO r60.8 remains installed in place with its original first-install time.
SAM-R01 has no customer/device surface, so an APK build or OPPO replay would be
duplicate work and is not authorized by this child.

SAM-R01 supplies the pure membership contract prerequisite. It does not close
UAW-R16: the persistent store adapter and authenticated account query remain
SAM-R02/SAM-R03 dependencies and must pass their own environment/security
gates before a real workspace can reopen.
