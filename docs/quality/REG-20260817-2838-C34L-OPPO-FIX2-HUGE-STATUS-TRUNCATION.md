# REG2838 — C34L OPPO FIX2 huge status truncation

Date: 17 August 2026
State: registered read-only reconstruction recurrence; zero mutation

## Mistake

The OPPO FIX2 agent ran full `git status --short --branch` against the known huge
dirty tree. Its approximately 143,659-token output truncated; the visible branch
was correct but scoped owner status had not yet been obtained. No file changed.

## Prevention

Treat the exact full status command as boundary-only, verify branch and HEAD as
independent scalar commands, and inspect only the two assigned OPPO owners with
explicit scoped status. Do not depend on the full dirty-tree body.
