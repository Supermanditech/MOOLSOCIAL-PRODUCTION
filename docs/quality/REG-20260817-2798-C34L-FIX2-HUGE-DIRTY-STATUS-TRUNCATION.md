# REG2798 — C34L FIX2 huge dirty status truncation

Date: 17 August 2026
State: registered read-only reconstruction truncation; zero mutation

## Mistake

The FIX2 transition agent ran full `git status --short --branch` with a
20,000-token output cap against the known huge dirty tree. The result contained
6,535 lines/about 134,925 original tokens and truncated, so it is inadmissible
as complete status evidence. The visible branch was not used as completion
evidence and no mutation followed.

## Prevention

Run the exact full status command only for boundary confirmation, then inspect
assigned owners with explicit scoped status calls. Never expect the complete
dirty-tree inventory to fit a direct tool result.
