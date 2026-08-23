# UAW-C33K PowerShell foreach pipeline parser error

- Regression: `REG-20260815-2525-C33K-POWERSHELL-FOREACH-PIPELINE-PARSER-ERROR`
- Date: 2026-08-15
- Scope: sanitized read-only verification of the two public Digital Asset Links endpoints.
- Failure: PowerShell rejected the initial one-line command because a `foreach` statement was piped directly to `Format-Table` without first collecting or grouping its output.
- Impact: no network request ran, no repository or external state changed, and no private value was accessed or printed.
- Prevention: collect the loop results into a task-specific variable, format only that collection, and expose only public origin, HTTP status, exact package-match count, and presence of a SHA-256 fingerprint.
- Retry gate: this entry existed before the corrected read-only command ran.
- Resolution: the corrected command assigned the `foreach` output to a scoped
  collection, then returned HTTP 200, one exact `com.moolsocial.app` match and
  SHA-256 fingerprint presence for each of the two public origins.
