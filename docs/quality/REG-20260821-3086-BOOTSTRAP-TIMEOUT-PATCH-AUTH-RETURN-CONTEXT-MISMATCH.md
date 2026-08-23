# REG3086 — bootstrap timeout patch auth-return context mismatch

- Date: 2026-08-21
- Status: registered before retry

A single-file bootstrap patch was rejected atomically because its final
auth-return context did not match the current formatted `main.dart`. No source,
build, device or external state changed.

Prevention: read the exact current bootstrap and auth-return ranges, then apply
independent bounded hunks with readback after each section.
