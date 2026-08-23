# REG-20260817-2737: C34L registry projection and memory gate combined call

## Truthful event

After REG2735 and REG2736 were appended, one PowerShell shell call first
projected the registry count, final ID and SHA-256 and then invoked the
regression-memory implementation gate. Both visible operations succeeded, but
the gate result is not admitted because release work requires one authoritative
gate per shell call.

No candidate state, source seal, cycle, AAB, device, Google Play, credential,
secret, deployment, or external state changed.

## Root cause

The post-append verification treated a successful scalar projection and the
owning machine gate as one convenience batch instead of preserving their
independent evidence boundaries.

## Prevention

- Run registry parse/count/hash projection in its own read-only call.
- Run `check-codex-development-regression-memory.ps1` alone in a separate call.
- Never count a combined gate invocation as qualification evidence even when
  every visible line reports success.

## Candidate consequence

C34L remains selection-only at zero release actions. The combined call changed
no candidate state; only its gate result must be replayed independently.
