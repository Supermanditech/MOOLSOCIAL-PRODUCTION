# C30N MVP gate range-read truncation rejection

- ID: `REG-20260812-1466-C30N-MVP-GATE-RANGE-READ-TRUNCATION-REJECTION`
- Date: 2026-08-12
- Scope: local read-only MVP scope-gate vocabulary audit
- Result: output truncated; no runtime, source, build, install, cloud or device mutation occurred

The first C30N gate-source inspection requested one dense 75-line range. The
tool output exceeded the available context and was rejected. None of that
partial output is accepted. C30N reads the same source through exact smaller,
non-overlapping ranges and confirms complete coverage before changing the
machine-state value.
