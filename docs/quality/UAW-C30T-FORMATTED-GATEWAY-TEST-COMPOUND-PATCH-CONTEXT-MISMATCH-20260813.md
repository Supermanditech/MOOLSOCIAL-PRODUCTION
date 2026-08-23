# C30T formatted gateway-test compound patch context mismatch

- Regression: `REG-20260813-1971-C30T-FORMATTED-GATEWAY-TEST-COMPOUND-PATCH-CONTEXT-MISMATCH`
- Ticket: `UAW-C30T-PRE-AAB-FEED-COMMENT-REPLY-DEAD-END`
- Result: patch rejected with zero mutation.

The negative response-containment test patch expected a one-line test
declaration that `dart format` had already wrapped. It also combined two test
insertions with a helper edit. The correction must reread current context and
apply independent exact patches.

This incident does not authorize an AAB, upload, install, deployment or device
mutation.
