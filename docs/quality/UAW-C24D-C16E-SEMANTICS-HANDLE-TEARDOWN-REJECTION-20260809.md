# C24D C16E semantics-handle teardown rejection — 2026-08-09

The migrated C16E journey passed its UI assertions but left the explicit
`SemanticsHandle` active until an `addTearDown` callback. Flutter verifies
semantics handles before that callback and rejected the test.

The correction disposes the handle synchronously in the test body with
`try/finally`. Journey and Ride sessions retain normal registered teardown.
