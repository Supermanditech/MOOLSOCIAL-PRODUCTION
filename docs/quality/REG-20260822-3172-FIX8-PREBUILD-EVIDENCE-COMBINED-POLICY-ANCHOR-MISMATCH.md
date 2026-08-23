# REG3172 - FIX8 prebuild evidence combined policy anchor mismatch

## Classification

Registered atomic patch rejection with zero evidence or candidate-state write.

## Evidence

The first patch combined two new prebuild evidence files with a coordination
policy owner append and used a stale policy-tail anchor. `apply_patch` rejected
the entire patch before any file was created.

## Prevention

Create the evidence files in one bounded patch, then read the current policy
tail and add their owner claims with a separate unique hunk. Never combine new
artifact creation with an unverified mutable policy-tail anchor.
