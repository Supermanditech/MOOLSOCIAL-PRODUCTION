# C30M Cloud Run format-expression argument rejection

- ID: `REG-20260812-1460-C30M-CLOUD-RUN-FORMAT-EXPRESSION-ARGUMENT-REJECTION`
- Date: 2026-08-12
- Scope: read-only pre-deployment Cloud Run invariant check
- Result: failed before dry-run or deployment; no cloud mutation occurred

All local gates passed, but the scripted Cloud Run reader constructed the
native gcloud `--format` argument using an inline parenthesized PowerShell
expression. The direct previously proven command uses one materialized literal
`json(...)` argument. C30M switches to that exact argument form and preserves
gcloud stderr on a nonzero child so a read-only metadata failure cannot hide
its diagnostic. Deployment had not been marked attempted and no runtime or
cloud resource changed.
