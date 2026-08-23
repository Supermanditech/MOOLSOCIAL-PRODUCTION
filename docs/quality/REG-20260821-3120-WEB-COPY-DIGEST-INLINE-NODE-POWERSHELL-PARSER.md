# REG-20260821-3120 — Web copy-digest inline Node PowerShell parser

Date: 21 August 2026
State: registered; command body did not execute

## Failure

A read-only inline `node -e` command intended to compute the updated deletion-
page copy digest was rejected by PowerShell before Node execution. JavaScript
regular-expression brackets were parsed as PowerShell syntax.

## Impact

- No digest was produced and no file, test, deployment or external state
  changed.

## Root cause

Shell-sensitive JavaScript regex syntax was embedded in a PowerShell native
argument instead of using a repository-owned test/helper boundary.

## Prevention

Do not retry nested inline quoting. Update the already-owned web test with the
new FIX7 semantic assertions, let its native mismatch report the exact current
digest or use a repository-owned helper, then patch the one digest literal and
rerun the exact web suite.
