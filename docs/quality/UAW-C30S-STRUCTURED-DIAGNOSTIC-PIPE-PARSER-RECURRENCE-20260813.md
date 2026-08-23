# C30S structured diagnostic pipe parser recurrence

Date: 2026-08-13

The first AST diagnostic for the post-build binding failure repeated the REG-1631 construction mistake: it piped directly after a complex `foreach` block in a one-line PowerShell command. PowerShell rejected it before execution. No artifact, state, device, Play, Firebase or provider mutation occurred.

All subsequent structured diagnostics must assign results to a named array, terminate the statement and format separately. The diagnostic scriptblock should be parsed before execution.

Regression: `REG-20260813-1633-C30S-STRUCTURED-DIAGNOSTIC-PIPE-PARSER-RECURRENCE`.
