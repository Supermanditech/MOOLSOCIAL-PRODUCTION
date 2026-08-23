# C30D semantics-handle teardown-timing rejection

- Regression: `REG-20260811-1372-C30D-SEMANTICS-HANDLE-TEARDOWN-TIMING-REJECTION`
- Date: 2026-08-11
- Focused result: two cases passed; the OPPO semantics case was rejected only because its `SemanticsHandle` remained active at Flutter end-of-test verification.
- Correction: dispose the handle explicitly after the last semantics assertion and before returning from the test body.
