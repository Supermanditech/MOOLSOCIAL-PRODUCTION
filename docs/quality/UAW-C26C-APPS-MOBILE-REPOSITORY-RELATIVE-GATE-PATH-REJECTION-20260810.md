# C26C apps/mobile repository-relative gate path rejection

## Observation

Two C26 gates were invoked from `apps/mobile` through `../../../scripts`; PowerShell correctly reported both paths missing.

## Cause

The repository root is two parents above `apps/mobile`, not three.

## Permanent prevention

- Run repository machine gates from the repository root.
- Use the verified `scripts/<gate>.ps1` literal path there.
- Never infer nested parent depth immediately before a qualification retry.

## Resolution evidence

The retry is performed from the exact production repository root after the permanent regression-memory gate passes.
