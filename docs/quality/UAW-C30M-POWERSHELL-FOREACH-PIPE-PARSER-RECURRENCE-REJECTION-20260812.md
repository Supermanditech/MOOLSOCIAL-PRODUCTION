# C30M PowerShell foreach-pipe parser recurrence rejection

- ID: `REG-20260812-1435-C30M-POWERSHELL-FOREACH-PIPE-PARSER-RECURRENCE-REJECTION`
- Date: 2026-08-12
- Scope: local read-only required-reading inventory
- Result: parser rejection; no source, cloud or device mutation occurred

The first inventory piped directly from a `foreach` statement. C30M retries only after materializing the loop output in a task-specific array, then serializing that array.
