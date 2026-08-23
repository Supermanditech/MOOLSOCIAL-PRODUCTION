# C30T Comment repository test-double contract omission

- Regression: `REG-20260813-1968-C30T-COMMENT-REPOSITORY-TEST-DOUBLE-CONTRACT-OMISSION`
- Ticket: `UAW-C30T-PRE-AAB-FEED-COMMENT-REPLY-DEAD-END`
- Typecheck result: rejected until the test implementation is complete.

The Social repository contract gained `comments` and `reply`, but the service
test `FakeRepository` still implemented only the prior operations. TypeScript
correctly rejected the incomplete interface implementation.

The correction must add method-specific fake state and behavior plus tests for
public pagination and verified bounded replies. This incident does not
authorize an AAB, upload, install, deployment or device mutation.
