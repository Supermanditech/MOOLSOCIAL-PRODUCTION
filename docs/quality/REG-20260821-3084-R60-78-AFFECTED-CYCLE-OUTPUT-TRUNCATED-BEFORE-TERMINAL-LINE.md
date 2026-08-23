# REG3084 — r60.78 affected cycle output truncated before terminal line

- Date: 2026-08-21
- Status: registered before retry

The first broad successor test command emitted enough progress to exceed the
tool output budget. Although the process ended, the returned output did not
contain its terminal pass/fail line, so it is not accepted as qualification
evidence. No build or device action followed.

Prevention: capture verbose Flutter test output in memory, retain the process
exit code, and emit only a bounded terminal summary with the final completed
test count.
