# C30O qualifier compact-log tail CPU spin and outer timeout rejection — 2026-08-12

## Disposition

Cycle 1r rejected. Format, analysis, 193 Flutter tests and the three source gates passed in durable logs, but the qualifier did not seal its result JSON. The outer command timed out at 124 seconds and left its exact PowerShell process consuming CPU with no child process. No AAB build, device, provider, console or account state changed.

## Mistake

After the compact Flutter test log reported `All tests passed!`, the qualifier attempted a bounded `Get-Content -Tail` over the carriage-return progress log. The PowerShell process continued consuming CPU, did not emit the cycle JSON, and outlived the tool timeout.

## Root cause

The cycle sealer treated a compact reporter log as a normal newline-delimited tail owner, repeating the known compact-output hazard in a different post-processing surface.

## Prevention before retry

- Pass the permanent regression-memory gate.
- Stop only the verified orphan qualifier process.
- Replace compact-log tail extraction with one exact `All tests passed!` match and a boolean summary.
- Preserve the complete rejected 1r logs and restart cycle 1 under `1rr` filenames with a longer outer timeout.
