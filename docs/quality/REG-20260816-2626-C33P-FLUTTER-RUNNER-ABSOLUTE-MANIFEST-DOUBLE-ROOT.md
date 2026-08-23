# REG-20260816-2626 — C33P Flutter runner received an absolute manifest path

Date: 2026-08-16 IST

C33P Cycle 1 completed its opening manifest comparison and all static gates in
both PowerShell hosts. The authoritative Flutter runner then stopped before
executing any test because orchestration passed an absolute focused-manifest
path while the runner contract joins `-Manifest` to `-RepositoryRoot`. The
resulting doubled path did not exist. No Flutter, analyzer, backend or web test
result is counted; no build, Play write or device action ran.

The correction is to retain the partial cycle logs, count no C33P cycle,
register this post-seal incident and reject C33P at `0/0/0/0`. A separately
selected successor must preflight the literal runner interface before sealing
and pass the focused manifest as a repository-relative path. It must seal
against the updated registry and complete two new independent cycles before
any build authority exists.
