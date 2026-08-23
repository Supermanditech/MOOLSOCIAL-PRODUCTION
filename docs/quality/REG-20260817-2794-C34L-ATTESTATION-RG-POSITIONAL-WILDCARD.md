# REG2794 — C34L attestation rg positional wildcard

Date: 17 August 2026
State: registered read-only search recurrence; zero mutation

## Mistake

While paused, the evidence-attestation agent passed Windows positional wildcard
paths such as `scripts/check-release*` and `scripts/write-release*` to `rg`.
Windows rejected the invalid path shape with OS error 123 before the intended
source search. No repository or external state changed.

## Prevention

Discover owners with `rg --files` and pipe the bounded file list to a fixed
string or reviewed regex search. Do not pass shell-style positional wildcard
paths to `rg` on Windows.
