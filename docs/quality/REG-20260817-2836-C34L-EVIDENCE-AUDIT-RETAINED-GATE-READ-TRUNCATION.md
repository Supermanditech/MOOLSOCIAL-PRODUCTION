# REG2836 — C34L evidence-audit retained-gate read truncation

Date: 17 August 2026
State: registered read-only audit owner truncation; zero mutation

## Mistake

The independent evidence auditor read the complete retained-evidence gate in one
result. A 396-token block inside `Assert-C34LSourceAttestation` was truncated
despite a larger exec allowance, leaving the core trust-boundary review
incomplete. No later command, test, or mutation followed.

## Prevention

Page this and every remaining source owner longer than roughly 400 lines in
independent nonoverlapping chunks of at most 160 lines through verified EOF.
Never scale only the output cap for dense trust-boundary source.
