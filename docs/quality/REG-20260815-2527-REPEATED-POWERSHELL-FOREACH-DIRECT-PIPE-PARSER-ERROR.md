# REG-20260815-2527 repeated PowerShell foreach direct-pipe parser error

- Date: 2026-08-15
- Predecessor: `REG-20260815-2525-C33K-POWERSHELL-FOREACH-PIPELINE-PARSER-ERROR`
- Failure: the next-action repository inventory repeated the prohibited
  `foreach (...) { ... } | Format-Table` form and failed at parse time.
- Impact: no command body, network request, repository write, Firebase action,
  release action or device action ran.
- Root cause: the active same-day prevention was not applied before the first
  compound read-only command of the continuation.
- Strengthened prevention: collect every `foreach` result first and only then
  format it; run the applicable regression-memory gate before the corrected
  inventory retry.
- Resolution: after the registry correction, the `general` memory gate passed
  and the inventory completed with the collection-first pattern.
