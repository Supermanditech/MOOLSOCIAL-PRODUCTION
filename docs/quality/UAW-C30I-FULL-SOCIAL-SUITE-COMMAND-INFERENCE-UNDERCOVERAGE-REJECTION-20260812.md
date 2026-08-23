# REG-20260812-1391 — C30I full Social suite command inference undercoverage rejection

- Phase: C30I full regression qualification
- Failure: A command inferred from two visible `loading` paths in a prior 164-test log passed only 17 tests. It is a focused matrix, not a complete Social cycle.
- Rejection: `artifacts/quality/uaw-c30i-social-suite-cycle-1-20260812-01/flutter-test.log` is preserved as undercoverage evidence and must not be counted as either required full cycle.
- Permanent prevention: Recover the complete suite definition from an explicit prior command/script or enumerate the exact intended test inventory before execution. Assert the expected test count at the end of every claimed full cycle.
- Protected state: No source rollback, build, install or deployment occurred.
