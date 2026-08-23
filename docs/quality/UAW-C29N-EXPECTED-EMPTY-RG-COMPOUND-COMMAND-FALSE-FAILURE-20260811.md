# C29N expected-empty ripgrep compound-command false failure

Date: 2026-08-11
State: resolved; permanent prevention active
Regression: `REG-20260811-1224-C29N-EXPECTED-EMPTY-RG-COMPOUND-COMMAND-FALSE-FAILURE`

## Preserved observation

After the C29N Flutter owners were formatted, a bounded verification shell call
appended a search for the removed constructor name and stale header expectation.
The format completed, the search correctly found nothing, and ripgrep returned
its documented no-match exit code 1. The compound call was nevertheless reported
as failed. A subsequent registry inventory repeated the same shaping error when
the searched C29N entry did not yet exist.

No product source, Flutter analysis, test, APK, device or provider operation
failed. The failure was limited to command composition.

## Root cause and prevention

An expected-empty search was used as the terminal native process in a compound
PowerShell command without explicitly interpreting its result. All successor
absence checks run independently, capture `LASTEXITCODE`, accept 1 only when the
output is empty, reject values above 1, and reject any returned prohibited text.
Formatting, inventory and evidence reads are never coupled to an expected-empty
search.

The permanent registry checker remains the machine gate for this durable rule.
