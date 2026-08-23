# C11 ripgrep Windows wildcard operand recurrence

- Regression: `REG-20260807-256-C11-RG-WINDOWS-WILDCARD-OPERAND-RECURRENCE`
- Date: 2026-08-07 IST

## Observation

A source search supplied `apps/mobile/lib/ui_v2/buy/*.dart` directly to
ripgrep on Windows. Ripgrep rejected the literal wildcard path, and the shared
parallel failure boundary also discarded a valid bounded test-file read.

## Permanent correction

Ripgrep receives exact literal files or directories only. File patterns are
expressed with `--glob` against an existing literal root, and independent reads
do not share a failure boundary when partial output is needed for diagnosis.
