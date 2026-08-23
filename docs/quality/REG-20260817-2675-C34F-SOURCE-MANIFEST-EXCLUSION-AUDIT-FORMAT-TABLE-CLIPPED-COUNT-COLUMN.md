# C34F source-manifest exclusion audit Format-Table clipped count column

Date: 2026-08-17 IST

Status: registered pre-seal; labeled scalar projection required

A read-only exclusion audit formatted long target paths and match counts with
`Format-Table`. Console width clipped the match-count column, so the result is
unknown and is not evidence that mutable state, aggregate and fixture owners
are excluded from the source manifest.

Do not treat the registry-2645 official file as a final seal. Rebind the next
registry generation, print each exact target and `ManifestMatches` value with
`Format-List`, require all counts zero, then generate and byte-compare a fresh
draft and official manifest before state binding. No source cycle, hidden
input, build, browser, Play or OPPO action occurred.
