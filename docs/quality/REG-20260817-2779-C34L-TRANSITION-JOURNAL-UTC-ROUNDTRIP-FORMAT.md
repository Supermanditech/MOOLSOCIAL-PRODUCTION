# REG2779 — C34L transition journal UTC round-trip format

Date: 17 August 2026
State: registered first transition FIX1 fixture failure; no real action

## Mistake

After parser qualification, the first PowerShell 7 lifecycle fixture reached
journal reconciliation and rejected `preparedUtc` as not an exact UTC
timestamp. The newly shared exact-UTC validator and the existing journal
timestamp generator used different fractional-second wire formats. The agent
stopped without diagnostic, retry or patch; fixture cleanup completed and no
real candidate, browser, build, Play, OPPO, private or external action occurred.

## Root cause and prevention

The browser-session UTC contract was applied to existing journal timestamps
without first round-tripping every timestamp producer. Define one invariant
wire formatter for each exact contract (or a single shared one), generate and
parse journal `preparedUtc`/`committedUtc`/reconciliation timestamps through it,
and add both-host new/existing journal history plus malformed/non-UTC negatives
before wider FIX1 tests.
