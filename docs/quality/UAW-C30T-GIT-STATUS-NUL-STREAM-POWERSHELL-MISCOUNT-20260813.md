# C30T Git status NUL-stream PowerShell miscount

## Incident

The first bounded dirty-tree reconciliation captured
`git status --porcelain=v1 -z` into a PowerShell variable and counted the
captured objects as records. PowerShell exposed the captured NUL-delimited
stream as one string, so the resulting count of one dirty entry was false and
was rejected immediately.

## Impact

The bad count is not used as repository evidence. The diagnostic was read-only;
it changed no tracked file, untracked evidence, Git reference, build, external
service or device state.

## Prevention

Use line-delimited porcelain status for bounded count/hash reconciliation when
filenames are not printed. Validate each line's two-column porcelain prefix,
count records from that validated array, and hash a deterministic UTF-8 line
join. A future NUL-delimited diagnostic must use an explicit raw-byte stream
owner and prove its framing before its count is admitted.
