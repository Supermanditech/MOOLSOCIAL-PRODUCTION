# Backend console truncation recurrence

Date: 2026-08-14
Incident: `REG-20260814-2168-AAB-BACKEND-CONSOLE-TRUNCATION-RECURRENCE`
State: registered before retry

The backend test process exited zero and displayed the final 528 passed / 0
failed summary, but printing all test cases directly caused tool truncation.
Under the regression-memory rule, that direct rendering is not complete cycle
evidence. The backend portion of cycle 1 is therefore not accepted.

The retry must use a new in-repository compile directory and immutable complete
log, parse exact TAP summary scalars, and render only a bounded tail. The first
run and its outputs remain preserved.

## Resolution

The retry captured complete compile and test output to unique UTF-8 logs inside
the production repository and rendered only exact summary scalars plus nine
tail lines. It proved 53 compiled test files, 528 tests, 528 passes, 0 failures
and exit 0 without truncation.
