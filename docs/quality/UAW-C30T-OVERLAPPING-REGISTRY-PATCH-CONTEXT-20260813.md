# C30T overlapping registry patch context — 2026-08-13

## Failure

A correction patch targeted REG-1688 twice through overlapping contexts: once for its status and again as the insertion anchor for a successor entry. `apply_patch` rejected the complete patch.

## Impact

No file or external state changed from the rejected patch.

## Prevention

Use one exact contiguous hunk when an existing registry entry must be updated and a successor entry appended. Keep evidence-document edits separate.
