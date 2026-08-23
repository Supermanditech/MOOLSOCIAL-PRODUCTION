# REG2796 — C34L partial premature-evidence correction

Date: 17 August 2026
State: registered pre-retry registry readback finding; zero gate retry

## Mistake

The REG2795 correction removed the nonexistent attestation-checker path from
REG2790 but left the same future path in the newly added REG2792 and REG2794
evidence arrays. This was identified from the applied patch before rerunning
the memory gate; no retry or owner action occurred.

## Prevention

When correcting a missing registry-evidence owner, inventory every occurrence
in the bounded patch/readback and remove all future-path references in the same
registered correction before the single fresh memory-gate run.
