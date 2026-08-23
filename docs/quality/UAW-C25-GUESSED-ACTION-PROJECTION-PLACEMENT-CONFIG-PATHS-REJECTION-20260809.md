# C25 guessed action-projection and placement config paths — rejection

Date: 2026-08-09

## Rejected audit

The first C25 governing-state audit attempted to read these inferred paths:

- `config/mvp-personal-action-projection.json`
- `config/personal-subaction-placement-regression.json`

Neither file exists. No evidence from those failed reads is admitted and neither guessed path may be retried.

## Permanent correction

Before selecting or implementing C25, enumerate exact repository paths with `rg --files config`, then bind all governing-state reads, ticket dependencies and gates only to the returned owners. The permanent regression-memory gate must pass before the inventory retry.
