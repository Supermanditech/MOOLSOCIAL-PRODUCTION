# C30T SemanticsHandle addTearDown lifecycle

- Regression: `REG-20260813-1996-C30T-SEMANTICS-HANDLE-ADDTEARDOWN-LIFECYCLE`
- Ticket: `UAW-C30T-R60-45-AUTH-CHOOSE-ANOTHER-METHOD-ZERO-BOUNDS`
- Result: the test resource is disposed before widget-test end verification.

All new semantics and geometry assertions passed, but the test deferred handle
disposal through `addTearDown`. Flutter verifies semantics handles while the
handle was still active. The corrected test owns disposal in a `try/finally`
inside its asynchronous body.

This incident does not authorize an AAB, upload, install, deployment or device
mutation.
