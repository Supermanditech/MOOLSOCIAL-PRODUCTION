# C25F chained record-read command rejection

- Date: 2026-08-09
- Status: registered before C25F selection

Three read-only record reads were placed in one PowerShell command separated by semicolons. That repeated the command-chaining class prohibited by REG-20260809-781, even though two reads succeeded.

Future repository reads and checks remain one explicit command purpose per shell call.
