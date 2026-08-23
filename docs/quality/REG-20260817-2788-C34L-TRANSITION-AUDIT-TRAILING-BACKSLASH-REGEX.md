# REG2788 — C34L transition audit trailing-backslash regex

Date: 17 August 2026
State: registered read-only inspection failure; no test or external action

## Mistake

The independent transition auditor used a compound `Select-String` regex whose
pattern ended with an unescaped backslash. Regex parsing failed before any
repository mutation, fixture or external action, and the auditor stopped
without retry.

## Prevention

Use `-SimpleMatch` or fixed-string `rg` for exact PowerShell source anchors.
When regex is unavoidable, search one reviewed literal pattern at a time and
reject trailing escape characters before invocation.
