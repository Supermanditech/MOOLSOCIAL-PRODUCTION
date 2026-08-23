# C30N Play Integrity nonce logcat exposure rejection

Date: 2026-08-12
Candidate: `UAW-PERSONAL-MVP-SOCIAL-PUBLIC-FEED-CREATE-OPPO-QUALIFICATION-C30N`
Installed version: `1.0.0-r60.40` (`2026081240`)

## Rejected diagnostic attempt

A broad Android logcat filter captured the complete Play Core integrity request
line while diagnosing the Dev Feed failure. That operating-system line included
a one-time request nonce. The value is intentionally not reproduced in this
repository and was not used, persisted or treated as an application credential.

## Root cause

The diagnostic selected the request-construction line instead of limiting the
read to completion, callback and redacted error markers.

## Permanent prevention

- Never read or retain a complete Play Integrity request line.
- Exclude every line containing `nonce=` or request payload fields.
- Query only bounded completion/callback/error markers and redact any
  request-like field before tool output or durable evidence.
- Preserve the installed app and all prior evidence; this rejection does not
  authorize a new build, install, app-data mutation or provider change.

## Disposition

The broad log read is rejected as diagnostic evidence. All subsequent C30N
device diagnostics must pass the active regression-memory gate and use the
bounded redacted pattern above.
