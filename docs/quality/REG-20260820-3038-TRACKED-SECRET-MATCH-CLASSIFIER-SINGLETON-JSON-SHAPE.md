# REG-20260820-3038 tracked secret-match classifier singleton JSON shape

## Incident

Primary ran the post-REG3037 private classifier over tracked paths matching the
secret-exclusion classes. PowerShell returned one JSON object because exactly
one owner matched. The JavaScript wrapper assumed an array and called `.map`,
raising `TypeError: items.map is not a function` before any path or
classification was emitted.

## Impact

- No path, content or value was emitted.
- No repository, B1 worktree, manifest, staging, commit or tag state changed.
- The classification result is unaccepted until shape-normalized retry.

## Root cause

PowerShell `ConvertTo-Json` collapses a singleton collection to one object, but
the wrapper did not normalize object-or-array JSON before mapping.

## Prevention

Do not retry the wrapper text. Normalize parsed JSON using
`Array.isArray(value) ? value : [value]`, retain the path only in private
session storage, and emit only extension/size/hash/secret-marker booleans until
the owner is proven sanitized.
