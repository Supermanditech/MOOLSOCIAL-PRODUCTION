# C30M hash-variant foreach-pipe parser recurrence rejection

- ID: `REG-20260812-1453-C30M-HASH-VARIANT-FOREACH-PIPE-PARSER-RECURRENCE-REJECTION`
- Date: 2026-08-12
- Scope: local secret-free runtime ownership comparison
- Result: parser rejection; no file or cloud mutation occurred

The deterministic hash comparison again piped directly from a `foreach`
statement, recurring after REG-20260812-1435. No hash result was produced or
accepted. C30M materializes the variant records into a task-specific array and
serializes only after the loop completes.
