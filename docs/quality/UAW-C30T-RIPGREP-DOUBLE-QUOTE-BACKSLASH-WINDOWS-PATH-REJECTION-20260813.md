# UAW C30T ripgrep double-quote/backslash Windows-path rejection — 2026-08-13

## Outcome

The backend discovery tried to pass `case \"feed\"` in a PowerShell
double-quoted command. Backslash is not the PowerShell double-quote escape, so
ripgrep received a malformed argument and treated `feed\` as a filesystem path.

The command exited 2 and is rejected. No state changed.

## Permanent prevention

Avoid quote-containing search patterns for this audit. Search simple exact
symbols such as `moolSocialContent`, `correctChoiceIndex`, and `closesAt`, then
read the returned exact file. Never use backslash as a PowerShell quote escape.
