# C33G FIX4 registry compact-array patch-context regression

- Regression: `REG-20260815-2454-C33G-FIX4-REGISTRY-COMPACT-ARRAY-PATCH-CONTEXT`
- Failure: the first qualification patch targeted parsed, expanded JSON instead of the registry's exact compact serialized arrays.
- Impact: `apply_patch` rejected the atomic patch; the FIX4 ticket state and qualification document remained unchanged/absent.
- Prevention: re-read and patch exact current serialized lines, then parse and run regression memory before continuing.
