# C30A foreach-pipe parser inspection rejection

- Regression: `REG-20260811-1351-C30A-FOREACH-PIPE-PARSER-INSPECTION-REJECTION`
- Date: 2026-08-11
- Result: command rejected before target state was established.

The bounded path inspection piped directly from a PowerShell `foreach` statement and failed parsing. It produced no accepted target evidence and made no product, device or external mutation.

Future bounded multi-path checks assign the `foreach` results to a task-specific variable before serialization. The failed command is not reused as evidence.
