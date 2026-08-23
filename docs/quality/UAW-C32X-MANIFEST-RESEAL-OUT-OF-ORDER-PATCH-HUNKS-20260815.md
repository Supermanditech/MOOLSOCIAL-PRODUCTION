# C32X manifest reseal out-of-order patch hunks

The first final-reseal patch was atomically rejected. It supplied the registry
row, later C32X evidence rows and then the earlier alphabetic
`ACTIVE-CODEX-HANDOFF.md` row. The patch matcher could not return to the earlier
file position, so no manifest line changed.

REG-2292 records the failure before retry. The bounded retry must use separate
or strictly path-ordered hunks, incorporate the newly registered registry and
evidence bytes, then validate real-tab structure, uniqueness and every current
file hash from scratch.
