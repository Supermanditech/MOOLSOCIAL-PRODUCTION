# UAW C33E MVP scope-state broad projection output truncation

Date: 2026-08-15
Regression: `REG-20260815-2348-C33E-MVP-SCOPE-STATE-BROAD-PROJECTION-OUTPUT-TRUNCATED`

## Failure

A read-only audit serialized several top-level sections of the append-heavy MVP scope state in one result. Historical assessment content made the output truncate.

## Root cause and recovery

The projection included nested historical assessment owners when only current ticket, execution, authorization, disclosure and provider scalars were required. The partial broad projection is discarded. Future reads must select exact current scalar paths and named current assessment fields only; historical arrays or objects must be queried separately and only when required.

No scope, source, build, provider, device or release state changed.
