# Post-YouTube backlog combined optional inventory exit-one recurrence

Date: 2026-08-15

The first route/screen/backlog inventory launched three independent ripgrep
commands under one all-success aggregate. One optional search returned the
valid no-match exit code 1, so the aggregate rejected and retained no per-leg
output. The entire call is zero audit evidence.

This repeats the class registered in REG-2229. Every corrected inventory is
therefore run separately, captures `LASTEXITCODE`, accepts only 0 or 1, and
prints an explicit no-match record for 1. Raw optional ripgrep calls are not
aggregated under `Promise.all`. No runtime source, service, build, Play or OPPO
state changed.
