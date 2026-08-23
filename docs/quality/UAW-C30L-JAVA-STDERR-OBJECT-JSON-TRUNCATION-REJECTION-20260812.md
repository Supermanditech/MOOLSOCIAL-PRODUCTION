# C30L Java stderr-object JSON truncation

- Scope: local read-only host qualification.
- Rejection: `java -version` stderr became a PowerShell `ErrorRecord` and produced a depth-truncated JSON object rather than a bounded version string.
- Prevention: stringify a bounded native stderr line before serialization and never admit an ErrorRecord object as machine evidence.
- Cloud/device impact: none.
