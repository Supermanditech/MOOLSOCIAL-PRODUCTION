# UAW C33J FIX1 registry append patch context mismatch

- Regression: `REG-20260815-2508-C33J-FIX1-REGISTRY-APPEND-PATCH-CONTEXT-MISMATCH`
- Failure: the first REG2507 patch used mismatched compound context and was
  rejected without changing files.
- Prevention: inspect the exact registry tail and append through its literal
  final evidence/array-close anchor.
- Impact: no product or external state changed.
