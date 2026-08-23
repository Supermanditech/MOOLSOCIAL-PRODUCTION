# C11 SemanticsHandle deferred-disposal recurrence

Date: 2026-08-07

Regression ID:
`REG-20260807-246-C11-SEMANTICS-HANDLE-DEFERRED-DISPOSAL-RECURRENCE`

The first C11 test repeated REG-209 by placing `SemanticsHandle.dispose()` in
`addTearDown`. Flutter verifies active handles before deferred cleanup, so the
remaining destination rows failed even after their product assertions ran.

Permanent prevention: every test that calls `ensureSemantics()` owns the
handle inside `try/finally` and disposes it before the test body returns. Test
environment and session cleanup may remain in the same `finally`; deferred
teardown is never used for a semantics handle.
