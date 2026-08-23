# REG2846 — C34L OPPO FIX2 parser foreach pipeline

Date: 17 August 2026
State: registered diagnostic-wrapper parser recurrence; zero owner parsing

## Mistake

The bounded OPPO parser diagnostic piped directly from a statement-level
`foreach` block into `ConvertTo-Json`. PowerShell rejected the wrapper with
`An empty pipe element is not allowed` before either owner was parsed. No retry
or owner-line inspection followed.

## Prevention

Assign loop results to a dedicated collection variable, then serialize that
collection in a separate statement. Do not pipe from statement-level
`foreach`; parse one owner per command where practical.
