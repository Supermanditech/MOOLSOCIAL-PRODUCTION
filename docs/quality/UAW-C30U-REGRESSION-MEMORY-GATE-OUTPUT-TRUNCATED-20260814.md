# C30U regression-memory gate output truncation

Date: 2026-08-14

Ticket: `UAW-C30U-POST-R60-45-SOCIAL-REPAIRS-PLAY-INTERNAL-ACCEPTANCE`

## Incident

The direct implementation-phase regression-memory gate invocation exceeded the
tool output boundary. Its rendered result was truncated, so it is not accepted
as a pass and no later test or qualification action may rely on it.

## Root cause

The gate was emitted directly into the task transcript instead of capturing its
complete output under a unique retained attempt path and returning only a
bounded final summary.

## Prevention

The retry must run the same gate as the sole authoritative action in its shell
call, preserve stdout and stderr in a new immutable C30U evidence log, capture
the process exit immediately, and emit only the bounded final lines. Existing
failed or partial evidence is never overwritten.

## Release effect

No AAB, upload, Play activation, installation or OPPO mutation occurred. C30U
build, upload and install counts remain zero and build authority remains closed.

## Bounded retry result

- Exit code: `0`
- Complete output lines: `1`
- Complete output SHA-256:
  `06279EA1F734DB3CAA6C3E871D88B48DD31D6C72E4F266070A48040ECB1ADC6B`
- Complete output: `Codex regression memory passed: entries=2013;
  applicable=1112; phase=implementation; buildMode=none.`

The retry ran as the sole authoritative action in its shell call. Its complete
one-line output is retained above; the truncated invocation remains rejected.
