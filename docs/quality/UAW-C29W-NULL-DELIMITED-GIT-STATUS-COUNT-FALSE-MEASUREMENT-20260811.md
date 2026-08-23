# C29W null-delimited Git status count false measurement

- Date: 2026-08-11
- Result: scalar count rejected

A PowerShell probe treated null-delimited `git status --porcelain=v1 -z` output as one pipeline object and emitted `status_records=1`. That value is rejected and is not used as dirty-tree evidence. The corrected method captures line-delimited porcelain output as an array and emits only its scalar count. No repository file was removed, reset or overwritten.
