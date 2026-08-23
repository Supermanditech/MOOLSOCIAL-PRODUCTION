# C24G Journey protected Work owner inference rejection

Date: 2026-08-09
Regression: `REG-20260809-740-C24G-JOURNEY-PROTECTED-WORK-OWNER-INFERRED-FROM-DIRECT-MOUNT`

The protected `/app/work` journey begins before setup and authentication and
runs with the Journey01 legacy-presentation test flag. Its completion owner
cannot be inferred from a direct signed-in `/app/work` mount. The attempted
`work-earn-screen` assertion failed and is rejected. The correction must trace
the protected redirect builder, retain `returnTo == null`, and bind to the
actual completed owner.

## Resolution

Router inspection proved the protected test-only owner is
`mvp-action-root-work`. The corrected Journey01 file passed all 12 tests,
including return-target clearance and the separate production Work connected
chooser journey.
