# REG2722 — C34J verification owner and evidence path guesses

Date: 2026-08-17 IST

During pre-seal verification, a command guessed the generic AAB wrapper checker
as `scripts/check-play-internal-aab-build-c30t.ps1`; that path does not exist.
A follow-up evidence read also abbreviated the exact REG2721 document filename
instead of discovering it first. Both reads failed before the intended checker
or document read, with no candidate transition, build, external write, test
evidence, or source-cycle authority consumed.

The repository inventory identifies the exact generic checker as
`scripts/check-play-internal-aab-build-wrapper-c30t.ps1` and the exact retained
REG2721 evidence path from `rg --files`. Future release verification must
discover and assert an owner's exact path before invocation and must use the
registry's literal evidence paths rather than reconstructing filenames from an
entry ID.
