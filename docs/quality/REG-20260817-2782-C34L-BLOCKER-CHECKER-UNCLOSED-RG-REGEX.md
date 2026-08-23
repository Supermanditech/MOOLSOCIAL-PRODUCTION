# REG2782 — C34L blocker checker unclosed rg regex

Date: 17 August 2026
State: registered read-only inspection failure; no test or external action

## Mistake

During bounded inspection of its exclusive checker, the PRE-AAB-3 agent issued
an `rg` pattern with an unclosed group. `rg` rejected the regex and the agent
stopped without retry, mutation or authoritative test after the last memory
gate. No browser, provider, release, private or external action occurred.

## Prevention

Use fixed-string searches for exact source anchors. When regex is necessary,
construct and validate one small literal pattern with balanced groups before
execution; never combine multiple source-variable anchors into an unreviewed
alternation.
