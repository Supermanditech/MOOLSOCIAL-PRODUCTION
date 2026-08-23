# REG2802 — C34L FIX2 transition-owner raw-read truncation

Date: 17 August 2026
State: registered read-only owner reconstruction truncation; zero mutation

## Mistake

The FIX2 agent raw-read the 1,566-line/74,695-byte transition owner with a
nominal 30,000-token cap. The roughly 18,675-token/1,567-line projection was
still marked truncated, so the owner read is inadmissible. No mutation, test,
or external action followed.

## Prevention

Read every dense assigned PowerShell owner in independent nonoverlapping pages
of at most 100 lines through verified EOF. Do not use raw reads for these
owners, regardless of nominal output allowance.
