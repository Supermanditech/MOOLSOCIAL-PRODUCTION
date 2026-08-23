# REG-20260818-2955 C34P PowerShell interpolated-colon recurrence

Date: 18 August 2026 (IST)
State: registered before corrected byte inspection

## Incident

The byte-inspection command used `"$i:..."` while constructing a non-ASCII
character-position summary. PowerShell parsed the colon as part of the variable
reference and rejected the command before its body executed. It produced no
line-comparison evidence and changed no repository or external state.

## Root cause

The command repeated the durable prohibition against placing `:` immediately
after an interpolated PowerShell variable name.

## Prevention

Use the format operator for every position/code pair and avoid interpolation in
the corrected diagnostic. Keep the command read-only, emit only lengths,
ordinal-equality, first mismatch and non-ASCII scalar positions, and do not
retry the parser-rejected form.

## Retained evidence

- `config/mvp-scope-gate-state.json`
- `config/codex-development-regression-registry.json`
- this incident record
