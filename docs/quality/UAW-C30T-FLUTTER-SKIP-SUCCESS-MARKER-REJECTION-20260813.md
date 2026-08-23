# C30T Flutter skip-aware success-marker rejection

Date: 2026-08-13
Scope: C30T qualification cycle 1 focused Flutter partition

## Evidence

The complete focused partition returned exit code zero with 140 passing tests and one intentional skip. Flutter therefore ended the log with `All other tests passed!`, not `All tests passed!`. The qualifier rejected only its narrower redundant marker assertion after the successful command.

Static release readiness had passed. Backend/provider sealing had not yet run. No AAB build, upload, Play update, device mutation, backend write, Create write or Chat message occurred; counters remain zero.

## Resolution

The qualifier continues to require a zero Flutter exit code and now accepts exactly either `All tests passed!` or `All other tests passed!` as the success marker.
