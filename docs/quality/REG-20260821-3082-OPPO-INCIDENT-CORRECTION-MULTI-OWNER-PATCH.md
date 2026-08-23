# REG3082 — OPPO incident correction combined two owners

- Date: 2026-08-21
- Status: registered before device retry

One successful `apply_patch` operation both created REG3081 evidence and
corrected REG3080 evidence. Although both edits were accurate and no external
action occurred, this violated the repository rule requiring one owner per
bounded operation.

Prevention: create a new incident owner and correct a prior incident owner in
separate patch calls, reading each back independently.
