# C14 ripgrep end-of-options placed before globs

Date: 2026-08-08

Regression:
`REG-20260808-284-C14-RIPGREP-END-OF-OPTIONS-PLACED-BEFORE-GLOBS`

## Failure

The corrected option-leading-pattern lookup placed `--` before its `--glob`
arguments. Ripgrep therefore treated each glob option and value as a path and
exited with code 2.

## Prevention

Every ripgrep option and glob is declared before the end-of-options separator.
The exact order is options, globs, `--`, pattern, verified literal roots. The
code-2 output is discarded and cannot establish absence.
