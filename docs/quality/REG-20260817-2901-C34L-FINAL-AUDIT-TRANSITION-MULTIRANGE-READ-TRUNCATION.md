# REG2901 — C34L final-audit transition multirange read truncation

## Incident

On 2026-08-17, the independent final auditor loaded `scripts/invoke-release-lifecycle-transition-c34l.ps1` and emitted numbered ranges 813–1018, 1562–1933, and 2490–2763 in one command. The command exited zero, but the tool reported `Warning: truncated output`, with 12,291 original tokens and 855 output lines; content was omitted inside the 1562–1933 range.

## Impact

- The combined transition-owner read is inadmissible as complete audit evidence.
- No behavior gate, repository mutation, recovery, candidate, seal, cycle, build, Play, OPPO, browser, private/account, device, secret, or external action occurred.

## Root cause

Three dense, widely separated transition-owner ranges were combined into one output projection whose total size exceeded the available result budget.

## Prevention

- Read dense release owners in independent nonoverlapping pages of at most 100 lines.
- Verify every requested page returns without a truncation warning before advancing.
- Never combine multiple large page ranges in one command.
- Stop and register any output truncation even when the shell exit code is zero.

## Disposition

Registered before any retry. No omitted transition lines are accepted as reviewed.
