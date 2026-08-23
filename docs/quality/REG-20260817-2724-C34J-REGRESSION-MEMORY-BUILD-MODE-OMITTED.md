# REG2724 — C34J regression-memory build mode omitted

Date: 2026-08-17 IST

After correcting the regression-memory phase to `build`, the invocation omitted
the checker’s separately required `-BuildMode release`. The checker rejected
the default `none` before completing the build-phase memory gate. No candidate
transition, source cycle, build, external write, or evidence authority was
consumed.

The exact C34J release-preparation invocation is
`check-codex-development-regression-memory.ps1 -Phase build -BuildMode release`.
Future calls must inspect and supply dependent parameters together, not only
the primary enum value.
