# C30T mixed working-directory gate path

- Date: 2026-08-13
- Repository: `C:\GUARANTEED OUTCOME\MOOLSOCIAL-PRODUCTION`
- Scope: focused Flutter test retry

The command used `apps/mobile` as its working directory but referenced repository-root machine files with relative paths. The initial `Get-Content` failed, so the gate, formatter, and test did not run and no state changed.

The retry must run registry validation and the regression-memory gate from the repository root, then run the formatter and Flutter test separately from `apps/mobile`.
