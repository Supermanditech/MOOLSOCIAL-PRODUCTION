# UAW C33J multi-file patch unverified documentation-context regression

- Regression: `REG-20260815-2490-C33J-MULTIFILE-PATCH-UNVERIFIED-DOC-CONTEXT`
- Failure: the first ticket patch bundled new owners with historical documentation appends and used a prose sentence that did not match the wrapped file bytes. `apply_patch` rejected the patch atomically.
- Impact: none of that patch was applied; no source, reference, provider, email, build, Play or device state changed.
- Prevention: add new owners independently, inspect exact documentation tails, and use verified terminal anchors for separate additive corrections.
