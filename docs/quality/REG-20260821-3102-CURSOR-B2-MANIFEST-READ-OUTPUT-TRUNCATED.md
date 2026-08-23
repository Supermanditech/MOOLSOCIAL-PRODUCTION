# REG3102 — Cursor B2 manifest read output truncated

- Date: 2026-08-21
- Status: registered; result not accepted
- Task: `/root/pre_buy_baseline_b0`

Cursor reported that a B2 manifest read emitted output beyond its bounded
result budget and truncated before a complete terminal audit result. No source,
manifest, staging, commit, tag, build, provider, Play or OPPO action followed.

Prevention: never emit manifest entries or filenames; compute counts, bytes and
SHA-256 in memory, capture stdout/stderr separately, and emit only the bounded
aggregate with exit code. Cursor may retry only after receiving this literal
incident path and the refreshed registry binding from the primary.
