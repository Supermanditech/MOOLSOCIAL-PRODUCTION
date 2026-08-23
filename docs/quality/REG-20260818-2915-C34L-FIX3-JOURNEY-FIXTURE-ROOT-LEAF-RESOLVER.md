# REG2915 — C34L FIX3 journey fixture root passed through leaf-only resolver

## Incident

On 2026-08-18, the first PowerShell 7 authoritative-journey fixture run rejected the positive fixture with `fixture run root is missing`. The adapter passed a directory path through the generic source-path resolver, which enforces `PathType Leaf`, before reaching the intended exact-directory assertion.

## Impact

- The journey adapter positive fixture did not execute its intended source checks.
- No retry, diagnosis command, later edit, Windows PowerShell run, real journey, browser, device, private/account, candidate, build, Play, OPPO or external action followed.
- The adapter/checker files remain preserved for bounded correction after policy replay.

## Root cause

One resolver encoded a leaf-file invariant but was reused for both immutable receipt files and the checker-owned fixture run directory.

## Prevention

- Use a dedicated exact-directory resolver, or an explicit path-kind parameter that validates `Container` separately from `Leaf`.
- Resolve and canonicalize the unique fixture run root before resolving children; require every child to remain under that exact root.
- Add positive directory-root and negative file-as-root/directory-as-leaf/reparse-ancestor fixtures on both hosts.
- Resume only after the primary registers this incident, the mandatory coordination policy is read, and memory/policy gates pass.

## Disposition

Registered by the primary as the unique next ID. The subagent did not allocate or append its own registry entry.
