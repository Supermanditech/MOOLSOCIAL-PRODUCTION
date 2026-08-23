# UAW C10 multi-file test patch hunk recurrence

## Incident

A C10B patch combined one contract and four test files. An empty hunk marker
appeared immediately before the final `Update File` header, so `apply_patch`
rejected the entire operation before writing any file.

## Prevention

Contract and test reconciliation now uses small file-bounded patches. Each
operation ends with a complete hunk and is applied before the next file group
is prepared. Rejected multi-file patch output is never treated as mutation.

No product, test, APK or OPPO file changed in the rejected operation.
