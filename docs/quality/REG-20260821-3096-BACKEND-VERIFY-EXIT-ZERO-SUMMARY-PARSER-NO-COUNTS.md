# REG3096 — backend verify exited zero but summary parser captured no counts

- Date: 2026-08-21
- Status: registered before evidence retry

`npm run verify` completed with exit code 0, covering TypeScript typecheck, build
and Node tests. The bounded parser expected TAP summary lines beginning with
`#`, but the active Node reporter used another prefix, so test/pass/fail counts
were returned as unavailable. No source, build candidate, device or external
action followed.

Prevention: capture a bounded raw reporter tail once, identify the active
summary syntax, and parse that exact format before accepting count evidence.
