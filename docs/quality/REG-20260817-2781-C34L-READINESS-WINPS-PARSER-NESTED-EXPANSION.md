# REG2781 — C34L readiness WinPS parser nested expansion

Date: 17 August 2026
State: registered parser-wrapper failure; no behavior or external action

## Mistake

After PowerShell 7 parsing passed, the PRE-AAB-1 agent embedded `$tokens`,
`$errors` and `$_` inside an outer double-quoted Windows PowerShell `-Command`.
The outer host expanded them and produced `[ref],[ref]`, `.Count` and an empty
pipeline. Windows PowerShell rejected the wrapper before the readiness parser
or fixture ran. The agent stopped without retry or further mutation.

## Prevention

Do not transport parser variables through nested double-quoted command text.
When ready, invoke the executable readiness owner directly with `-File` on each
host so its own parser/self-test is authoritative. If parse-only evidence is
needed, use a previously qualified literal script block with no interpolating
outer layer.
