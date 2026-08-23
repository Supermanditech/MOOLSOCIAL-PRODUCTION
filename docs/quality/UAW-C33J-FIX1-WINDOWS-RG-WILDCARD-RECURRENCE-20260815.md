# UAW C33J FIX1 Windows rg wildcard recurrence

- Regression: `REG-20260815-2503-C33J-FIX1-WINDOWS-RG-WILDCARD-RECURRENCE`
- Failure: a read-only lookup passed `apps/mobile/test/uaw_c33j*` as a
  positional Windows path and emitted OS error 123.
- Impact: the lookup transcript was mixed and cannot be treated as complete;
  no product or external state changed.
- Prevention: use a verified directory root and `rg -g` for filename filters.
