# C14 ripgrep option-leading pattern missing separator

Date: 2026-08-08

Regression:
`REG-20260808-283-C14-RIPGREP-OPTION-LEADING-PATTERN-MISSING-SEPARATOR`

## Failure

A read-only search for bounded Flutter reporter helpers used a pattern that
started with `--machine`. Ripgrep parsed the pattern as an unsupported option
and exited before searching.

## Prevention

Any ripgrep pattern whose first character is `-` is preceded by the explicit
`--` end-of-options separator. The failed output is not treated as absence;
the corrected lookup is a new exact command with the same verified roots.
