# C20C guessed C20B static-gate filename — rejection

- Date: 2026-08-08
- Scope: C20C host implementation only
- Mutation before rejection: none
- Device/build/install impact: none; closed

## Observed mistake

A compatibility inspection converted the C20B disclosure/overflow ticket title
into a plausible checker path that is not present in `scripts`.

## Permanent prevention

Predecessor C20 checker paths must be copied literally from an
`rg --files scripts` result filtered by the ticket suffix. Descriptive ticket
titles are not filesystem paths.
