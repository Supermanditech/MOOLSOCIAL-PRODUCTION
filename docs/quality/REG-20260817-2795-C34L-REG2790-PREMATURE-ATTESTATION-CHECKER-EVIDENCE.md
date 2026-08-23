# REG2795 — C34L REG2790 premature attestation-checker evidence

Date: 17 August 2026
State: registered memory-gate rejection; zero owner test or external action

## Mistake

REG2790 listed `scripts/check-release-source-attestation-c34l.ps1` as retained
evidence before that planned owner existed. The implementation memory gate
failed closed on the missing repository evidence path; no agent retry or owner
test followed.

## Prevention

Regression entries may reference only retained paths that exist at registration
time. Planned owners remain in ticket text until created; add them as evidence
only in a later truthful registry generation after exact existence readback.
