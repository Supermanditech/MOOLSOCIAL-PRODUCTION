# UAW C33F Flutter authored-pass count undercount

Date: 2026-08-15
Regression: `REG-20260815-2367-C33F-FLUTTER-AUTHORED-PASS-COUNT-UNDERCOUNT`

The first valid C33F cycle-one Flutter execution completed successfully at the test framework level with 426 authored passes, 3 declared skips, 0 failures, 0 error events, 0 non-JSON lines, 0 untyped JSON objects and Flutter exit code 0. The authoritative runner rejected it because the command expected 425 passes. The expectation added eight tests based on a narrow line-anchored source regex, but the current 60-file reporter manifest contains nine additional authored passes versus the earlier 417-pass baseline. The attempt is not counted as a qualification cycle.

Recovery: register before retry, identify the complete authored-test delta using the test framework/reporter semantics rather than a formatting-sensitive source regex, set the exact expectation to 426, and restart cycle 1 from immutable-manifest comparison. Do not weaken the runner's exact pass/skip/failure checks.
