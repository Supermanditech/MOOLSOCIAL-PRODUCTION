# C30S exported-component diagnostic pipe parser error

Date: 2026-08-13

A read-only PowerShell diagnostic intended to project exported manifest node details placed a pipeline directly after a malformed `foreach` closing expression. PowerShell rejected the command before execution. No file, device, provider, Play, Firebase or build state changed.

The corrected diagnostic must materialize the `foreach` output in a named array and format it in a separate statement. Complex diagnostic scriptblocks should be parsed before execution where practical.

Regression: `REG-20260813-1631-C30S-EXPORTED-COMPONENT-DIAGNOSTIC-PIPE-PARSER-ERROR`.
