# C09 connected Social stale-ribbon failure

Date: 7 August 2026

The first connected regression cycle reached 134 passes and six failures in
`screen04_universal_v2_conformance_test.dart`. Those tests still tapped Mool
and searched for the deleted Social-hosted `screen04-world-ribbon` and
`screen04-rail-<main-action>` controls. Production removed that main-action
ribbon in C03; Mool now opens `PersonalMoolRootV2`, and Social owns only Shorts,
Videos, Feed and Create.

REG-20260807-137 retains the failed cycle. The stale tests are updated to use
the production `mool-action-*` owner for cross-main-action journeys and the
Social choice ribbon only for active/next Social subaction visibility.
