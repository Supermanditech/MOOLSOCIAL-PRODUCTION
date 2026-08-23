# REG2932 — FIX3 journey final-writer captureValues uninitialized

## Observed event

The authoritative producer passed direct PS7 and WinPS receipt-only suites with three positives, fourteen negatives, and cleanup verified. In the first integrated final-writer PS7 run, Play and OPPO advanced, then the journey writer failed under StrictMode because `$captureValues` had not been set before use.

## Impact

- Authoritative producer dual-host qualification is green at the pre-final-writer boundary.
- Play and OPPO final-writer paths advanced.
- WinPS integrated writer run was not started; no ordering diagnosis, correction, retry, cleanup probe, real build, browser, Play, OPPO, journey, device, private, provider, or external action occurred.

## Root cause boundary

The journey writer's receipt-only production parameter-set flow reaches a shared validation/serialization site before initializing the capture-derived values used there.

## Mandatory prevention

1. Trace parameter-set control flow without printing receipt values.
2. Initialize one exact capture-derived structure in every valid parameter set before shared validation, or keep branches separate until both structures are complete.
3. Under StrictMode, assert required variables exist before the first shared site.
4. Add production receipt-only, fixture receipt, legacy fixture-capture, and invalid cross-parameter-set cases.
5. Parse, rerun fresh PS7 integrated authoritative-only, then WinPS; verify cleanup and zero real actions.
