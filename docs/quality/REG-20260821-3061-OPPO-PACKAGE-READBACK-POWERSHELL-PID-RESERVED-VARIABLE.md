# REG-20260821-3061 OPPO package readback PowerShell PID reserved variable

## Observed failure

The sanitized OPPO package diagnostic assigned app process text to `$pid`, but
PowerShell's `$PID` is read-only and case-insensitive. The process-running field
therefore reflected the host process and is rejected. Other independently parsed
package fields remain valid.

## Root cause

The diagnostic reused a reserved automatic-variable name.

## Impact

- the installed app was not launched, stopped, modified, pulled or inspected
  for private data;
- Play installer, version, target SDK and build flags were read successfully;
- only `APP_PROCESS_RUNNING` is invalid;
- no repository, build, Play or OPPO state changed.

## Prevention and authorized retry

Use a task-specific variable such as `$appPidText`, emit only the process-present
boolean, and never reuse PowerShell automatic-variable names.
