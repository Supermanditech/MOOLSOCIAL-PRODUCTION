# REG2835 — C34L evidence-audit OPPO-writer read truncation

Date: 17 August 2026
State: registered read-only audit owner truncation; zero mutation

## Mistake

The independent evidence auditor read the complete 1,005-line OPPO writer in
one result. Its approximately 10,894-token output exceeded the nested result
cap and truncated inside the trust-boundary implementation, so source review is
incomplete. No later command, test, or mutation followed.

## Prevention

Read this owner in independent nonoverlapping pages of at most 200 lines through
verified EOF, with each page's output bounded separately. Never accept a
truncated source owner as complete audit evidence.
