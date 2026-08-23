# REG-20260817-2739: C34L integration-audit combined read truncation

## Truthful event

Before its later parser stop, the integration-audit sub-agent grouped required
reconstruction owners into output that truncated. The partial output is not
accepted as a complete read. The agent made no edit and performed no retry.

No assigned owner, candidate state, source seal, cycle, AAB, device, Google
Play, credential, secret, deployment, or external state changed.

## Root cause

The agent combined substantive required owners without first measuring and
paging them independently.

## Prevention

- Read each substantive wrapper, launcher, checker, and handoff owner in an
  independent bounded call.
- Measure large owners and page them with verified nonoverlapping ranges.
- Reject every grouped truncated result in full before implementation.

## Candidate consequence

C34L remains selection-only at zero release actions. The truncated output is
zero complete-reconstruction evidence for that agent turn.
