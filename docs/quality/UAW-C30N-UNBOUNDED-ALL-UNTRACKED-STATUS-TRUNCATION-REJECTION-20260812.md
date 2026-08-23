# C30N unbounded all-untracked status truncation rejection

- ID: `REG-20260812-1464-C30N-UNBOUNDED-ALL-UNTRACKED-STATUS-TRUNCATION-REJECTION`
- Date: 2026-08-12
- Scope: local read-only successor reconciliation
- Result: output truncated; no runtime, source, build, install, cloud or device mutation occurred

The first C30N reconciliation materialized `git status --short
--untracked-files=all`. Windows emitted thousands of long-path warnings from
preserved browser evidence, and the tool output truncated even though the JSON
payload itself was bounded. None of that dirty-tree output is accepted. C30N
reuses the exact already-proven branch and HEAD, counts tracked changes with
`--untracked-files=no`, counts top-level untracked owners with
`--untracked-files=normal`, and never enumerates all preserved untracked files.
