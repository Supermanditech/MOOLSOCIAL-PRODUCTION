# REG-20260816-2632 — C33S incremental source-manifest owner set mismatched

Date: 2026-08-16 IST

The first C33S source manifest was composed by recomputing the C33R manifest
paths, adding the new C33S gate and recovery owner, and serializing rows with
LF. The authoritative `scripts/new-c30v-source-manifest.ps1 -ComparePath`
check rejected its bytes before any source cycle. The repository owner uses
`Environment.NewLine`; matching path/hash rows do not waive byte identity.

No source gate, hidden-input prompt, build, browser write, Play action or OPPO
action followed the rejection. The invalid 2,602-entry-bound manifest is
retained as pre-seal failure evidence and is not a qualified seal.

The exact correction is to register this incident, then use the authoritative
C30V script's `-OutputPath` mode as the only generator for a new registry-bound
manifest. Its own `-ComparePath` mode must pass before the first C33S source
gate or cycle.
