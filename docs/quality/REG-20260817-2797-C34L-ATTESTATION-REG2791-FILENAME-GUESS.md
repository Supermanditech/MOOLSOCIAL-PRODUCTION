# REG2797 — C34L attestation REG2791 filename guess

Date: 17 August 2026
State: registered read-only exact-path recurrence; zero mutation

## Mistake

After being told to reconstruct REG2791–REG2796, the evidence-attestation agent
guessed REG2791 as `REG-20260817-2791-C34L-DIFF-READ-SEMICOLON-CHAIN.md`.
`Get-Content` failed because the durable filename differs. The agent stopped
without discovery retry or mutation.

## Prevention

Resolve newly registered regression documents with a bounded `rg --files`
query for their numeric IDs before any read. Never convert a short incident
description into a conventional filename.
