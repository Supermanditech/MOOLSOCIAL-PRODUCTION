# REG2791 — C34L REG2790 patch-result truncation

Date: 17 August 2026
State: registered uncertain tool-result boundary; readback confirmed the mutation

## Mistake

The primary agent's `apply_patch` result was truncated while registering
REG2790, so the success of that mutation could not be accepted from the tool
result. No later mutation was attempted before read-only inspection confirmed
that the REG2790 document exists and the parsed registry contains it exactly
once.

## Prevention

Treat a truncated mutation result as unknown, stop mutation, and resolve the
exact target with bounded read-only existence, parse and cardinality checks.
Never infer success from the requested patch or repeat the patch blindly.
