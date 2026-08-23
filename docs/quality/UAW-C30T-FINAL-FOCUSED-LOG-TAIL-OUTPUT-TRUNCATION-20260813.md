# C30T final focused log tail output truncation

Date: 2026-08-13

The 57-file focused regression completed with exit code 0 and a complete immutable evidence log, but returning 45 verbose expanded-reporter tail lines caused the direct tool presentation to truncate.

Permanent prevention: return only the final summary line, hash and byte count. Inspect failures by exact test name rather than returning a large verbose tail.
