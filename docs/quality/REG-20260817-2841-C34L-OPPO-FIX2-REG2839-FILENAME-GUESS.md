# REG2841 — C34L OPPO FIX2 REG2839 filename guess

Date: 17 August 2026
State: registered read-only exact-path recurrence; zero mutation

## Mistake

The OPPO FIX2 agent guessed a topic-based REG2839 filename and `Get-Content`
failed, even though the primary's generation notice supplied the exact REG2839
path. REG2840 read succeeded; no owner mutation or test followed.

## Prevention

Copy the exact durable path from the primary notice verbatim. If a path is not
available in context, resolve the numeric ID with bounded `rg --files`; never
replace a supplied filename with a likely topic-derived name.
