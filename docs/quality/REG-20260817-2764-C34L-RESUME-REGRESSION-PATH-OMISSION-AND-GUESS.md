# REG2764 — C34L resume regression path omission and guess

Date: 17 August 2026
State: registered read-only path failure; no candidate or external action

## Mistake

Primary coordination told the PRE-AAB-1 agent to read `REG2763` but omitted its
exact durable filename. The agent then guessed
`REG-20260817-2763-C34L-EVIDENCE-FIXTURE-HASHTABLE-VS-PSOBJECT-MISMATCH.md`.
`Get-Content` failed because that owner does not exist, and the agent stopped
without discovery or retry. Two previously created selection-only JSON owners
remain preserved and untested; the readiness owner is still absent. No seal,
cycle, launcher, build, Play, OPPO, browser, device, private, secret or external
action followed.

## Root cause and prevention

The resume instruction gave a shorthand incident number instead of the exact
registered path, and the receiving agent converted the description into a
conventional filename rather than resolving it. Every resume message that
requires a new incident read must include its exact path. If a path is absent,
the receiver must use bounded `rg --files` discovery and never guess.
