# C24G registry status non-unique patch rejection

Date: 2026-08-09
Regression: `REG-20260809-743-C24G-REGISTRY-STATUS-PATCH-USED-NONUNIQUE-CONTEXT`

## Rejection

A status-only patch matched repeated status values without the immutable
regression IDs in its hunk context. It prematurely resolved the broad Work
suite gate (`REG736`) and failed to resolve the final corrected Journey entry
(`REG742`). The intermediate registry state is rejected.

## Permanent prevention

Patch each status within an exact regression-ID block. Parse the JSON and
verify the requested ID-to-status mapping immediately after every registry
status change.

## Resolution

An ID-anchored correction restored `REG736` to
`active_material_gate_rejected`, resolved `REG742`, and resolved this process
entry. Parsed verification found exactly one entry for each of REG736 and
REG740-REG743 with the intended status.
