# REG2799 — C34L FIX2 handoff raw-read truncation

Date: 17 August 2026
State: registered read-only reconstruction truncation; zero mutation

## Mistake

The FIX2 transition agent read the full active handoff with `Get-Content -Raw`.
The 9,878-line/about 130,308-token output truncated despite a large result cap,
so the handoff reconstruction was incomplete. No mutation, test, or external
action followed.

## Prevention

Locate the current checkpoint heading with a fixed-string bounded search, then
read nonoverlapping line pages small enough to fit through the required section
and its continuation list. Never raw-read the dense append-only handoff.
