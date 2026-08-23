# C28D bounds-table colon interpolation rejection

- Date: 2026-08-10
- Phase: read-only first-device-gate evidence formatting
- Rejection: after fixing the loop collection, a diagnostic string used
  `$semantic:` without braces, which PowerShell parsed as an invalid scoped
  variable reference before the read executed.
- Evidence effect: none; the captured screenshot/XML and the material gate's
  exact Mool bounds remain intact.
- Root cause: a colon immediately followed an unbraced interpolated variable.
- Prevention: use `${semantic}:` in PowerShell diagnostic strings. Do not retry
  the optional six-row table; preserve the already sufficient material-gate
  output instead.
