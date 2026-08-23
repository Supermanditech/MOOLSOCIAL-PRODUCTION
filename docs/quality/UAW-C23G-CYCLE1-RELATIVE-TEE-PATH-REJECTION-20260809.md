# C23G cycle 1 relative Tee path rejection — 2026-08-09

## Observed rejection

The first fresh cycle 1 invocation created the repository evidence directory
but passed a relative log path to `Tee-Object`. The qualifier entered
`apps/mobile`; the sink then attempted to open that relative path below the
mobile directory and failed. No cycle-pass seal was produced, so the attempt
counts as zero qualifying cycles.

## Permanent prevention

Resolve the evidence log to an absolute path before invoking the qualifier.
Only a complete retained log ending in the exact C23G cycle-pass fingerprint
seal counts toward the required two consecutive cycles.
