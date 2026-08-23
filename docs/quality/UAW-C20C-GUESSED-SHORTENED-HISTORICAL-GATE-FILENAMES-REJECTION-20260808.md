# C20C guessed shortened historical gate filenames — rejection

- Date: 2026-08-08
- Scope: C20C host implementation only
- Mutation before rejection: none
- Device/build/install impact: none; closed

## Observed mistake

The first compatibility-source inspection supplied shortened C16A, C17B,
C17D and C17E checker names that are not repository files. The same ticket
concepts are implemented by longer, specific script names.

## Permanent prevention

Historical gate paths must be selected from a bounded `rg --files scripts`
inventory and copied literally. A ticket label is not sufficient authority to
construct or abbreviate a checker filename.
