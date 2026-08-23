# C28C PowerShell script-harness false stop

- Date: 2026-08-10
- Phase: host-qualification preflight
- Passed first: the C28C aggregate host-qualification gate
- Rejection: the combined read-only shell harness tested `$LASTEXITCODE`
  after invoking a PowerShell script. The script did not set that native-process
  variable, so its retained value caused the harness to exit before invoking
  the qualifier preflight.
- Product/evidence effect: none; no source, runtime, build, install or host-cycle
  evidence changed, and r60.26 remained installed.
- Root cause: native-process exit-code state was used to determine success of a
  PowerShell script instead of relying on terminating errors under
  `$ErrorActionPreference = 'Stop'`.
- Prevention: invoke PowerShell gates in a fail-fast PowerShell scope and do not
  inspect `$LASTEXITCODE` after script invocations unless the script explicitly
  owns a native-process exit status. Run the pending qualifier preflight in an
  independent command.
