# UAW C30U guessed historical baseline path rejection

Date: 2026-08-14

## Incident

A read-only protected-inventory query included a remembered C24F baseline
directory that does not exist at the guessed path. Ripgrep returned exit 1, so
the combined lookup is not accepted as inventory evidence.

## Prevention

Use the verified C30U successor and C29E predecessor paths already named by the
gate. If another historical baseline is genuinely required, first resolve its
exact owner through a bounded file inventory and require exactly one result.

No source, baseline, machine state, release artifact, Google Play state or OPPO
state was changed by the failed lookup.
