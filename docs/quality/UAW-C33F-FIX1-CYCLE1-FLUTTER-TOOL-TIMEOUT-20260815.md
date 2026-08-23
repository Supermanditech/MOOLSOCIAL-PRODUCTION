# UAW C33F FIX1 cycle-1 Flutter tool-timeout correction

Date: 2026-08-15

## Registered mistake

The authoritative 60-file Flutter regression command was given only a
120-second shell timeout. The tool terminated the command before an
authoritative suite result was available.

## Safe correction

- Do not count the timed-out attempt as a cycle.
- Verify that no orphan Flutter test process remains.
- Restart cycle 1 from immutable-manifest comparison.
- Use a long bounded timeout and communicate through at-most-60-second waits.
- Preserve all build, upload, activation, install and device counters at zero.
