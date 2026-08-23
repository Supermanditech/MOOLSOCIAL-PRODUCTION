# REG3166 - MVP selected manifest wrong property depth

## Classification

Registered null projection rejected with zero state mutation.

## Evidence

The final seal queried `selectedAssessment.manifestSha256` and returned null despite the authorized FIX8 MVP gate passing. The null value is not credited as a manifest result.

## Prevention

Project the live top-level names and immediate selected parent, then compare the exact live manifest field to an independently computed ticket hash.
