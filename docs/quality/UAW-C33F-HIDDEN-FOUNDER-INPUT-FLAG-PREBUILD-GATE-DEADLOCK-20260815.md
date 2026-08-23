# UAW-C33F hidden founder-input flag prebuild-gate deadlock

Date: 2026-08-15

## Preserved failure

The exact r60.49 founder launcher accepted all three hidden founder inputs and then failed closed before generated release preflight or AAB execution. The wrapper invoked the mandatory C33F build-phase gate after the launcher had already persisted `hiddenFounderInputsEntered=true`; that gate correctly requires the flag to remain false while the single build authority is still `available_once`.

The launcher `finally` path erased transient files and process values and restored the prompt-state booleans. Read-only reconciliation proved machine state `source_and_live_readiness_qualified_founder_secret_prompt_required`, build authority `available_once`, build result `not_started`, and build/upload/install/device counts `0/0/0/0`. No AAB, Play action, OPPO action, provider deployment, email, or quota submission occurred. No hidden value was read or stored by Codex.

## Root cause

The static order contract proved the C33F gate before prompts and the wrapper gate before generated preflight, but it did not prove the cross-owner state transition between those boundaries. The launcher persisted the historical `hiddenFounderInputsEntered` marker before wrapper entry while the C33F gate interprets that same marker as evidence that the one prompt/build boundary is already consumed.

## Required correction

Keep `hiddenFounderInputsEntered=false` through wrapper entry and the wrapper-owned C33F build gate. Persist it only in the same wrapper transaction that consumes `buildAuthorization`, after release config and manifest preflight pass and immediately before the one appbundle execution. Strengthen the current C33F gate with exact cross-owner ordering/cardinality assertions and a behavioral no-build state-transition test. Reseal source and complete two fresh identical full cycles before another founder prompt.
