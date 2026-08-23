# REG-20260821-3055 Flutter analyze yielded session handle not preserved

## Observed failure

Whole-mobile `flutter analyze` exceeded the first 30-second tool yield. The
wrapper forwarded only initial output and did not preserve the returned session
handle or exit result. The exact process was observed until it exited, but its
outcome cannot be accepted.

## Root cause

The tool wrapper projected only `result.output` instead of retaining
`session_id` and polling it to terminal completion.

## Impact

- the original analyzer process completed and was not restarted concurrently;
- no analyzer result is claimed from that run;
- no source, build, Play, OPPO, provider or device state changed.

## Prevention and authorized retry

On any yielded `exec_command`, retain the returned session identifier and use
`write_stdin` until terminal completion. With warm caches, rerun once only after
registration and emit the final exit/output.
