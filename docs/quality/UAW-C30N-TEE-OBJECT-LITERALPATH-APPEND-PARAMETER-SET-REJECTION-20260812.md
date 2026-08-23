# C30N Tee-Object LiteralPath/Append parameter-set rejection

- ID: `REG-20260812-1470-C30N-TEE-OBJECT-LITERALPATH-APPEND-PARAMETER-SET-REJECTION`
- Date: 2026-08-12
- Scope: local C30N source-qualification cycle 1
- Result: cycle rejected before analysis/tests; no APK build, install, cloud or device mutation occurred

The first C30N cycle wrote the successful user-facing copy result to its
partial log, then PowerShell rejected `Tee-Object -LiteralPath ... -Append`
because that append switch belongs to the `-FilePath` parameter set. The
partial log is preserved and is not accepted as a cycle. The complete cycle
restarts under new evidence filenames using the already-resolved absolute path
with `Tee-Object -FilePath ... -Append`.
