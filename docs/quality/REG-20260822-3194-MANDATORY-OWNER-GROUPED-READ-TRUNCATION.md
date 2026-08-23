# REG-20260822-3194 — Mandatory-owner grouped read truncation

## Incident

Codex issued the coordination-policy Markdown and JSON reads together. The
combined result exceeded the output boundary and was truncated, so it could
not qualify either owner as a complete independent mandatory read.

## Impact

- Repository mutations before registration: `0`
- External actions: `0`
- APK builds: `0`
- OPPO actions: `0`

## Root cause

Parallel latency optimization was applied to owners whose coordination policy
requires a separate command/result and complete consumption.

## Permanent prevention

Every mandatory owner is read independently. Large owners are consumed in
non-overlapping bounded pages through a verified EOF, and any truncated output
is rejected before it can support a gate or release action.
