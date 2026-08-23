# C30T PowerShell foreach-pipe parser recurrence — 2026-08-13

## Failure

A read-only child-ticket inventory placed `| Format-Table` immediately after a `foreach` statement. PowerShell rejected the command with `An empty pipe element is not allowed` before any ticket was read.

## Impact

- No repository or external state changed.
- No build, upload, install, provider write or device action occurred.
- The intended inventory result was not produced.

## Prevention

Collect `foreach` output in an explicitly initialized array, then pipe that array to formatting. C30T retries must not pipe directly from a statement block.
