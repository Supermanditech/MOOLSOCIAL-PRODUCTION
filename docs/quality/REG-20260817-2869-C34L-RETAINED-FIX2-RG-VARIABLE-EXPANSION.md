# REG2869 — C34L retained FIX2 rg variable-expansion recurrence

- Status: registered read-only source-inspection mistake.
- Scope: retained/recovery FIX2 tooling only.
- Mistake: a double-quoted `rg` regex expanded PowerShell variables such as `$expectedCapture` and `$binding`, producing a malformed expression and exit 2.
- Root cause: source tokens containing `$` were placed in an interpolating diagnostic regex.
- Prevention: use single-quoted literal patterns or independent fixed-string searches; never place source `$` tokens inside double-quoted diagnostic regexes.
- Repository/external impact: no mutation, test retry, recovery action, or external action followed.
