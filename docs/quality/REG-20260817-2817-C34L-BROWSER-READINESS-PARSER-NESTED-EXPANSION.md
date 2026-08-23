# REG2817 — C34L browser-readiness parser nested expansion

Date: 17 August 2026
State: registered parser-wrapper recurrence; zero owner parser/external action

## Mistake

The browser-readiness agent invoked a parser through an outer double-quoted
`pwsh -Command`. The host expanded `$p` and `$null`, causing a not-recognized
command and missing `Resolve-Path -LiteralPath`, then the malformed wrapper
falsely printed a parser-pass message. No owner parser result is accepted, and
no later mutation, test, or external action followed.

## Prevention

Run stable checker owners directly with `-File` on each host or use one literal
target-owned parser block. Never put parser variables in outer interpolating
command text, and never emit pass output unless the parsed error collection was
created and proven empty by the target process.
