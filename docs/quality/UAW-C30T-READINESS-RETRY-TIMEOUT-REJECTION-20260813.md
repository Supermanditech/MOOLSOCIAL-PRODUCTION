# C30T release-readiness retry timeout rejection — 2026-08-13

## Finding

The first retry repeated the short-timeout failure because the shell tool invocation still used a one-second timeout. The intended two-minute minimum was not applied to the actual parameter.

## Containment

- No AAB, APK, upload, install, provider deployment, device write or external communication was performed.
- Both short-timeout logs are rejected as readiness evidence.
- A third invocation is permitted only after confirming no orphaned check process remains and setting `timeout_ms` to 180000 on the actual tool call.

## Permanent prevention

For long-running release gates, the effective tool parameters must be reviewed against the registry prevention rule before execution; an intended timeout documented only in reasoning is not sufficient.
