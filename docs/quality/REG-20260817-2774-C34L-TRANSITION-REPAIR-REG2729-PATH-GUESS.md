# REG2774 — C34L transition repair REG2729 path guess

Date: 17 August 2026
State: registered read-only reconstruction failure; no mutation

## Mistake

The transition-repair assignment named REG2729 without its exact durable path.
The agent guessed
`REG-20260817-2729-C34K-INDEPENDENT-PRE-AAB-AUDIT-BATCH.md`, and
`Get-Content -Raw` failed because that owner does not exist. The agent stopped
without discovery, retry, edit or test. No candidate or external action
occurred.

## Root cause and prevention

Primary coordination again omitted an exact required incident path, and the
agent inferred a descriptive filename instead of resolving it. Resume with the
literal authority
`docs/quality/REG-20260817-2729-C34K-CONSOLIDATED-PRE-AAB-LIFECYCLE-AUDIT-GAPS.md`.
Every assignment must include exact mandatory paths; missing paths must be
discovered with bounded `rg --files`, never guessed.
