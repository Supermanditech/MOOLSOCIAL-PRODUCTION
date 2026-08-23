# C30T exiting gate script skipped chained Flutter tests

## Incident

The prior-repair replay invoked the regression-memory PowerShell gate followed
by `flutter test` in the same shell command. The gate completed successfully but
terminates its PowerShell host with `exit`; the Flutter command was therefore
never executed.

## Impact

Only the memory gate passed. No Flutter test result is claimed from that
command, and no source, build, service or device state changed.

## Prevention

Run each gate that may own process exit in an independent tool process. Run the
test runner in a subsequent command and admit it only when the output includes
the runner's own completion line and exit code.
