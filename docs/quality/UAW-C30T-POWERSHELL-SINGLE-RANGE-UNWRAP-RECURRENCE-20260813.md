# C30T PowerShell single-range unwrap recurrence

## Observation

A read-only source-display helper represented each file's ranges as nested arrays. For a file with only one range, PowerShell unwrapped the outer collection and the loop received scalar integers rather than a two-element range. The display stopped before any mutation.

## Root cause

The diagnostic repeated the singleton-unwrapping class already registered for PowerShell XML query results.

## Permanent prevention

- Prefer explicit scalar start/end bounds for bounded displays.
- If a collection of ranges is necessary, force the outer array with the unary comma.
- Validate each range has exactly two integer elements before indexing it.
