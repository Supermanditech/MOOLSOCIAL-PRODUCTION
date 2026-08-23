# REG2877 — C34L retained FIX2 recovery patch stale anchor

- Status: registered zero-write patch rejection.
- Mistake: a recovery-owner patch included an unrelated trailing `if ($FixtureMode)` context that is absent from the live file, so the patch failed atomically.
- Root cause: a speculative second anchor was combined with the exact confinement change instead of using the freshly read local block alone.
- Prevention: reread the immediate `$stateFile` confinement block and apply one owner/one bounded hunk with no unrelated trailing anchor.
- Impact: the rejected patch wrote nothing; no later test, recovery action, release, private, or external action followed.
