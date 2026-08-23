# REG2878 — C34L FIX2 selection state retains raw device serial

- Status: registered primary cross-owner release blocker.
- Defect: the untracked C34L detailed selection state retains `candidate.deviceSerial = 2b3e0f71`, and the final transition identity validator requires that raw value. This violates the FIX2 ticket and capture contract, which require the approved nonreversible `deviceBindingSha256` and forbid raw device-identifier fields everywhere.
- Root cause: evidence producers migrated to the nonraw binding, but the earlier PRE-AAB-1 state schema and transition common-identity assertion were not included in that migration.
- Detection: primary exact token review after transition suites were reported green.
- Prevention: replace the candidate field with approved `deviceBindingSha256 = 97D9B2320D5FF975C73199BE18F7C50BE23A1C3C45D4F361FF713A7EB93532AF` in detailed/aggregate common identity as applicable; remove raw serial literals/field names from all C34L source and fixtures except explicit forbidden-name test data; update transition/readiness/fixtures and rerun all affected dual-host suites plus independent privacy audit.
- Boundary: do not derive, inspect, or retain any other private/device value and do not perform a real device action.
