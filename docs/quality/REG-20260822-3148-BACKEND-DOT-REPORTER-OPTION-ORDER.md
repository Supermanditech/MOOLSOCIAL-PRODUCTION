# REG-20260822-3148 — backend dot-reporter option order

Date: 22 August 2026

State: registered; visible 586/586 summary not sealed because output truncated

The complete backend test command appended `--test-reporter=dot` after the
package script's positional test glob. Node retained the verbose spec reporter,
and the tool output truncated despite a visible terminal 586/586 summary. The
process did not fail, but the run is not accepted as sealed cycle evidence.

No source correction, build, APK, OPPO, provider, account, email/SMS, Play or
cloud action followed the truncated output.

Root cause: the reporter option was appended through `npm test --` after the
script's positional operand instead of invoking the compiled tests with the
reporter option before the glob or capturing and summarizing the native stream.

Prevention: rebuild once, invoke `node --test --test-reporter=dot` with the
option before the verified compiled glob, capture stdout/stderr and native exit
in memory, and emit only explicit test/pass/fail/skipped totals.
