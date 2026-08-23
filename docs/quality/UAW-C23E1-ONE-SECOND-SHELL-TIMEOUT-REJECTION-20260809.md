# C23E1 one-second shell-timeout rejection — 2026-08-09

## Observed rejection

The corrected mobile verification completed no-diff Dart formatting, then the
one-second shell timeout terminated focused Flutter analysis before a result.
The focused tests did not run.

## Root cause

The nested command's terminating timeout was mistaken for the orchestration
layer's non-terminating early-yield interval.

## Permanent prevention

Use a realistic shell timeout for Flutter work and use the outer execution
yield to return progress without terminating the process. A timed-out analysis
has no result and authorizes no test or qualification claim.
