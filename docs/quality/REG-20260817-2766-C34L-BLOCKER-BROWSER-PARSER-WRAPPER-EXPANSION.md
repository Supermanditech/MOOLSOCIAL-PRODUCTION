# REG2766 — C34L blocker/browser parser wrapper expansion

Date: 17 August 2026
State: registered before source parser or fixture; no external action

## Mistake

The PRE-AAB-3 PowerShell 7 parser invocation embedded parser source containing
`$tokens`, `$errors` and `$_` inside an outer double-quoted `-Command` string.
The outer host expanded those tokens, producing malformed `[ref]`, `.Count`
and an empty pipeline element. The wrapper failed before the checker parser
ran, and the agent stopped without retry or test. No fixture, browser, provider,
candidate, release, private or external action occurred.

## Root cause and prevention

Parser code was transported through an interpolating command string instead of
executed from a literal script block or a temporary-free direct parser command.
Use direct `-File` for executable owners. For parse-only qualification, pass a
single-quoted literal script block to the target host or use a checked static
parser wrapper whose source-variable tokens cannot be expanded by another
PowerShell layer.
