# REG2830 — C34L OPPO nested probe omitted attestation scope

Date: 17 August 2026
State: registered insufficient correction; zero real/external/private action

## Mistake

After a checker-only correction, direct PS7 and WinPS OPPO suites—including
ordinary self-nesting and raw journal checks—passed, but the PS7 combined gate
still reproduced REG2829 before combined fixture creation. The new probe had not
reproduced the preceding source-attestation checker invocation in the same
caller scope. No WinPS combined retry followed; fixtures cleaned and no real,
external, or private action occurred.

## Prevention

Nested qualification must reproduce the exact two-step caller sequence:
source-attestation checker, then OPPO checker in one scope. On failure retain
only sanitized runtime token type/cardinality diagnostics—never raw journal or
private values—and correct the scope leak without weakening raw-wire validation.
