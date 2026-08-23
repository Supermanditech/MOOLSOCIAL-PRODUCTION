# REG2914 — C34L primary collision-repair patch context mismatch

## Incident

While correcting the concurrent REG2910 allocation, the primary combined two new durable documents with a registry ID/evidence-path rewrite in one patch. The patch was atomically rejected because the assumed single-line evidence-array context did not match the live formatted registry entry.

## Impact

- No hunk from the rejected patch applied; REG2912/REG2913 documents and registry corrections were not created by that attempt.
- Both FIX3 implementation agents were already stopped.
- No implementation, candidate, seal, cycle, build, Play, OPPO, browser, private/account, device, secret or external action occurred.

## Root cause

The primary patched a remembered/assumed evidence-line format instead of reading the exact live bounded registry entry before constructing a separate minimal hunk.

## Prevention

- Register this failed patch first.
- Read only the exact live duplicate P0 registry object and closing tail.
- Apply separate bounded patches: durable docs; exact ID/path correction; collision and patch-failure registry entries.
- Never combine unrelated Add File and speculative registry contexts in one patch.

## Disposition

Registered truthfully before any retry. The failed patch performed zero writes.
