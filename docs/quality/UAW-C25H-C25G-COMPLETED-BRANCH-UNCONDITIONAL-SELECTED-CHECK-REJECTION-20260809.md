# C25H C25G completed branch contradicted by selected check

Date: 2026-08-09

## Rejection

Under lawful C25H selection, the C25G aggregate passed its new completed-state
identity predicate but then rejected because a later unconditional assertion
still required its parent child state to equal `selected`.

## Recovery

The expected self-child state is now derived from the active/completed branch.
The full C25F-to-C25G-to-C25H replay chain is exercised before a final cycle
set is counted.

## Permanent rule

A new gate state path requires an audit of every downstream predicate.
