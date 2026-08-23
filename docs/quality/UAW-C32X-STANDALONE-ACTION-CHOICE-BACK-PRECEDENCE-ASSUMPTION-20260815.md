# C32X standalone action-choice Back precedence assumption

The first C32X retry reached 15 passes and then showed that a system Back in the
plain `MaterialApp` action-choice harness invokes the root `PopScope` callback
without dismissing the connected overlay. The exact current FIX2 authority does
not promise Back-to-close for this standalone no-op harness, and production
routes only render this action-choice owner when the tests-only legacy flag is
enabled.

C32X is corrected to verify launcher-toggle menu closure and then the root Back
callback. Runtime source remains unchanged.
