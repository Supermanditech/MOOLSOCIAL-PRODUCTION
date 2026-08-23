# C22G PowerShell reserved Host variable rejection

- Observed: 2026-08-08 during the first C22G qualifying host cycle.
- Rejection: `qualify-personal-capsule-system-host-c22g.ps1` assigned the
  contract object to `$host`; PowerShell resolves variable names
  case-insensitively, so this attempted to overwrite the read-only automatic
  `$Host` variable and stopped before format, analysis, tests or gates.
- Root cause: a generic local variable name collided with a PowerShell
  automatic variable.
- Permanent prevention: qualification scripts use domain-specific names for
  deserialized contract sections and the regression-memory gate retains this
  failure. The failed invocation is not a qualifying cycle.
- Runtime/device effect: none. No Flutter build, APK install or device mutation
  occurred; installed r60.20 remains preserved.
