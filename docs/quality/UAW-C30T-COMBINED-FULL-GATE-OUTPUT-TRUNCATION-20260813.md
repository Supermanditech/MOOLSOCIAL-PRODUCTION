# C30T combined full-gate output truncation

- Date: 2026-08-13
- Ticket: `UAW-PERSONAL-MVP-SOCIAL-PLAY-INTERNAL-LIVE-READ-RECOVERY-C30T`
- Regression: `REG-20260813-1883-C30T-COMBINED-FULL-GATE-OUTPUT-TRUNCATION`

## Observation

One combined predeployment command completed successfully with 505 backend tests passed, 7 Hosting tests passed, both deployment-control suites passed and the live read-only Cloud preflight passed. The interactive tool retained the final totals but truncated the middle of the 551-line transcript.

## Root cause and prevention

The full TAP output and several later gates were combined into one result. Final evidence must instead use separate immutable log files, each with its own exit result and SHA-256, while the console shows only bounded summaries.

## External effect

None. All cloud activity in this command was read-only; no provider or Hosting deployment occurred.
