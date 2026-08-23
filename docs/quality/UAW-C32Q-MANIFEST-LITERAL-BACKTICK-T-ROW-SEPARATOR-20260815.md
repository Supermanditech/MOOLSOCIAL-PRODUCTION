# UAW C32Q manifest literal backtick-t row separator

Date: 15 August 2026
Regression: `REG-20260815-2275-C32Q-MANIFEST-LITERAL-BACKTICK-T-ROW-SEPARATOR`

The first 32-file manifest calculation emitted literal `` `t `` text because its PowerShell format string was single-quoted. The resulting `2AD3C0...` aggregate is invalid, was not written to a manifest and must never be cited.

The exact unchanged path order will be recomputed with a real tab separator from a double-quoted format string. Output must be visually checked before the manifest is created.
