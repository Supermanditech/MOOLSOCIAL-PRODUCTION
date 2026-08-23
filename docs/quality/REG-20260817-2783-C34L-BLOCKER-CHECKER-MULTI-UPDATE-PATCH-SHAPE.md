# REG2783 — C34L blocker checker multi-update patch shape

Date: 17 August 2026
State: registered zero-write patch rejection

## Mistake

The PRE-AAB-3 agent placed multiple `*** Update File` operations for the same
checker in one `apply_patch` payload. Patch verification rejected the duplicate
target before mutation. The agent stopped without retry, test or gate; no
browser, candidate, release or external action occurred.

## Prevention

Use one `*** Update File` section per owner in each patch, containing all small
non-overlapping hunks for that owner. If a later hunk depends on earlier
context, apply and reread it in a separate patch rather than repeating the file
header in one payload.
