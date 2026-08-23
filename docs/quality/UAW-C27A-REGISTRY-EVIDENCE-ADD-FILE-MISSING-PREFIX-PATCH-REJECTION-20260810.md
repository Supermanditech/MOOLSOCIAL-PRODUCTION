# C27A registry-evidence add-file prefix patch rejection

## Observation

The first C27A evidence-and-registry patch omitted the required `+` prefix on
one line inside a new-file hunk. `apply_patch` rejected the complete patch
before mutation.

## Cause

A large multi-file patch was composed before the two evidence documents had
been added and verified independently.

## Permanent prevention

- Add and validate each new evidence document in its own bounded patch.
- Every line in an add-file hunk must begin with exactly one `+`.
- Append registry entries only after all referenced evidence paths exist.

## Resolution evidence

No file changed in the rejected attempt. This evidence is being added first in
a small exact patch before the registry append is retried.
