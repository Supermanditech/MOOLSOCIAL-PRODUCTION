# UAW C33F wrapper search interpolation correction

Date: 2026-08-15

## Registered mistake

A wrapper structure search used a double-quoted PowerShell regular expression
containing variable-shaped source tokens. PowerShell interpolation altered the
pattern, and ripgrep rejected the resulting expression.

## Safe correction

- Register before retry.
- Use independent fixed-string searches with single-quoted PowerShell literals.
- Never infer a passing wrapper contract from a failed or altered search.
- The failed read-only search consumed no release or external-service authority.
