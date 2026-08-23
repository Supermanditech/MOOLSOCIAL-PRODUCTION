# REG-20260817-2736: C34L sub-agent combined handoff read truncation

## Truthful event

The transaction sub-agent combined its required document reads into an output
large enough to truncate the active handoff. The visible partial output is not
accepted as complete reconstruction, and the sub-agent stopped before any
mutation or retry.

No file, candidate state, source seal, cycle, AAB, device, Google Play,
credential, secret, deployment, or external state changed.

## Root cause

The sub-agent grouped a dense append-only handoff with other required owners
instead of measuring it and reading the exact current section in a bounded
independent range.

## Prevention

- Read the active handoff independently from other substantive owners.
- Measure the line count before a complete read and use explicit nonoverlapping
  bounded ranges when complete coverage is required.
- For C34L reconstruction, read the exact 14:50 and 14:36 sections first and
  confirm their continuation boundary before implementation.

## Candidate consequence

C34L remains selection-only at zero release actions. The truncated read is zero
reconstruction evidence for that sub-agent and invalidates no qualified state.
