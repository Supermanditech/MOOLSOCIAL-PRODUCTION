# REG2872 — C34L transition FIX2 rg variable-expansion recurrence

- Status: registered read-only inspection mistake before correction.
- Mistake: a double-quoted `rg` expression containing `$capture`, `$attestation`, and `$value` was expanded by PowerShell, leaving an unclosed regex group.
- Root cause: source-variable tokens were placed in an interpolating search pattern despite the same prevention already applying to retained FIX2.
- Prevention: use separate single-quoted fixed-string searches for each source token; never use interpolating regex text for PowerShell source inspection.
- Impact: no transition mutation, test, release, private, device, or external action followed.
