# REG-20260815-2528 regression-memory unsupported planning phase

- Date: 2026-08-15
- Failure: the regression-memory checker rejected `-Phase planning` at
  parameter validation because its accepted values are `general`,
  `implementation`, `build` and `device`.
- Impact: the checker body did not run and no repository, service, release or
  device state changed.
- Prevention: use `-Phase general` for continuation-wide planning checks and
  inspect each gate's declared parameter contract before invocation.
- Resolution: the supported `general` phase passed with all 2,499 registered
  entries applicable.
