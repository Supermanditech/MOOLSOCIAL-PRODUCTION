# C29N ripgrep wildcard positional-path recurrence

Date: 2026-08-11
State: resolved; permanent prevention active
Regression: `REG-20260811-1229-C29N-RIPGREP-WILDCARD-POSITIONAL-PATH-RECURRENCE`

## Preserved observation

During bounded inspection of protected navigation tests, exact file reads
completed successfully. A final ripgrep search supplied a Windows wildcard
filename as a positional path, which the operating system rejected with error
123. Product source and tests were not changed by the failed search.

## Prevention

All successor inventories search an exact confirmed directory with a ripgrep
`-g` filter or consume an exact completed file list. Wildcard filenames are
never positional inputs, and search calls are isolated from evidence reads.
