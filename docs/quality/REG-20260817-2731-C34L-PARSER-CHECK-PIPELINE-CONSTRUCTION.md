# REG-20260817-2731: C34L parser-check pipeline construction

## Truthful event

A read-only multi-file PowerShell parser command attempted to pipe directly after a `foreach` statement. PowerShell rejected the command with an empty-pipe parser error before any target script was parsed.

No candidate state, source candidate, AAB, device, Google Play, secret, deployment, or external state changed.

## Root cause and prevention

The ad hoc checker did not collect loop results before formatting. Future parser checks collect result objects into a task-specific array and format them only after the loop completes.

## Candidate consequence

C34L remains selection-only with zero release actions. No qualified seal or cycle existed to invalidate.
