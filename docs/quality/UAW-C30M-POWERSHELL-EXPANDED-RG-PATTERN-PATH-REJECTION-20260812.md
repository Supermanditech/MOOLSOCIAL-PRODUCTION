# C30M PowerShell-expanded rg pattern/path rejection

- ID: `REG-20260812-1458-C30M-POWERSHELL-EXPANDED-RG-PATTERN-PATH-REJECTION`
- Date: 2026-08-12
- Scope: local backend package-owner read
- Result: one pattern was expanded/misparsed as a path; no source or cloud mutation occurred

The third fixed-string pattern was placed in a PowerShell double-quoted command
and contained `$repoRoot` plus escaping that produced a bogus positional path.
The partial matches are not accepted as complete inventory evidence. C30M uses
single-quoted fixed patterns or reads the already-known bounded line range
directly.
