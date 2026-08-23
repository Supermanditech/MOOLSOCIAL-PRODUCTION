# REG2911 — C34L FIX3 journey-adapter foreach-pipe parser

## Incident

On 18 August 2026, the FIX3 journey-adapter owner piped directly from a
statement-level PowerShell `foreach` block into `Format-Table` while collecting
bounded file metadata. PowerShell rejected the command before its body ran.

## Impact

The command returned no admissible metadata. No source, evidence, browser,
device, private, release or external state changed.

## Root cause

The metadata projection repeated the registered statement-level
`foreach`-pipeline construction instead of first materializing loop output or
reading one owner at a time.

## Prevention

Never pipe directly from a statement-level `foreach`. Assign loop results
before formatting, prefer scalar per-owner reads, and stop on the first parser
failure until the incident is registered and regression memory is replayed.

## Disposition

Registered before retry. C34L remains selection-only.
