# C30N regression-memory path lookup rejection

- ID: `REG-20260812-1467-C30N-REGRESSION-MEMORY-PATH-LOOKUP-REJECTION`
- Date: 2026-08-12
- Scope: local read-only regression-memory lookup
- Result: nonexistent path rejected; no runtime, source, build, install, cloud or device mutation occurred

The resumed C30N audit guessed `docs/quality/permanent-regression-memory.json`,
which does not exist. The two requested evidence documents were read, but the
combined command exited nonzero on the missing path. C30N resolves the
repository-owned memory file from tracked paths before reading or updating it
and does not reuse the guessed location.
