# REG-20260817-2733: C34L MVP-state top-level projection assumption

## Truthful event

A read-only C34L reconstruction command parsed the current MVP scope and
robustness checkpoint owners, then projected candidate and assessment fields
from assumed top-level property names. Those fields are nested in the current
schemas, so the projection emitted blanks and is not accepted as scope or
robustness evidence.

The exact ticket hash and the two top-level state values were read correctly.
No candidate state, source seal, cycle, AAB, device, Google Play, credential,
secret, deployment, or external state changed.

## Root cause

The command reused remembered projection paths before enumerating the exact
current root and nested property names.

## Prevention

- Enumerate the exact current root property names first.
- Enumerate the selected-ticket and robustness-assessment child property names
  before projecting values.
- Reject every blank or null projected release-control value and never infer it
  from the surrounding handoff.
- Run the owning MVP scope and delivery-discipline gates after the schema-aware
  projection.

## Candidate consequence

C34L remains selection-only at zero release actions. There is no detailed or
aggregate C34L candidate state, source seal, cycle, founder input, AAB, Play
write, install, or OPPO acceptance to invalidate.
