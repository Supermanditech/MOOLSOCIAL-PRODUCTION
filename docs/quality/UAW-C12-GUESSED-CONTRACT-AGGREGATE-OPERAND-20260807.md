# C12 guessed contract aggregate operand

- Regression: `REG-20260807-269-C12-GUESSED-CONTRACT-AGGREGATE-OPERAND`
- Phase: pre-build source sealing

The first bounded C12 contract aggregate included the guessed path
`config/mvp-personal-action-projection.json`. That file does not exist. Because
the helper did not stop on `Get-FileHash` error, it still printed an invalid
aggregate and a zero shell exit; that output was discarded.

Prevention: every aggregate operand is first resolved from `rg --files` or an
exact already-read path, the helper throws when any operand is missing, and
the aggregate result is accepted only after the command exits cleanly with no
PowerShell error record.
