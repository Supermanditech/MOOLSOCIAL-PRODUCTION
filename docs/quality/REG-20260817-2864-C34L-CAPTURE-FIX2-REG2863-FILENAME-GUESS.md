# REG2864 — C34L capture FIX2 REG2863 filename guess

Date: 17 August 2026
State: registered read-only exact-path recurrence; zero mutation

## Mistake

The capture FIX2 agent read REG2862, then guessed an unrelated REG2863 filename
and `Get-Content` failed, even though the primary notice supplied REG2863's exact
path. No memory gate, cleanup, or mutation followed.

## Prevention

Copy every exact path from the primary notice verbatim. Never replace a supplied
filename with a topic-derived guess; if context is uncertain, discover the
numeric ID with bounded `rg --files` before reading.
