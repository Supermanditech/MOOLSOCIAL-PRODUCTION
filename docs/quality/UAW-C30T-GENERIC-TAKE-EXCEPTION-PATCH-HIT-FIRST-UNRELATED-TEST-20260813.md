# C30T generic take-exception patch hit unrelated test

- Regression: `REG-20260813-1985-C30T-GENERIC-TAKE-EXCEPTION-PATCH-HIT-FIRST-UNRELATED-TEST`
- Ticket: `UAW-C30T-PRE-AAB-FEED-AUTHOR-PROFILE-AND-FOLLOW-MISSING`
- Result: diagnostic mutation landed in the wrong test and must be restored.

The repeated `expect(tester.takeException(), isNull)` line was not a unique
anchor. Apply-patch changed the first occurrence in a guest-Create test rather
than the compact author test. The correction restores it and uses compact-
specific context for any diagnostic edit.

This incident does not authorize an AAB, upload, install, deployment or device
mutation.
