# C21 PowerShell variable-colon diagnostic parser rejection — 2026-08-08

Parser review rejected the first C21E gate because a double-quoted diagnostic used `$relative: $token`. PowerShell treated the colon as part of a scoped-variable reference and rejected the script before execution.

Variables immediately followed by punctuation in double-quoted PowerShell strings use `${relative}:` form. New gate scripts must pass parser review before their first execution or citation.
