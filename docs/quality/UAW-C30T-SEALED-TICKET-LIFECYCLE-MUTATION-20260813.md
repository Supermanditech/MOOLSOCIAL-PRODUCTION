# C30T sealed-ticket lifecycle mutation — 2026-08-13

## Failure

The aggregate C30T authorization ticket's `state` value was changed after source and Dev-provider completion. The robust-delivery lock rejected the resulting file because its SHA-256 no longer matched the immutable selected-ticket assessment.

## Impact

- The build gate failed closed.
- No AAB, upload, install or device mutation occurred.
- The separate machine-state and evidence updates remain the correct progress owners.

## Prevention

The sealed aggregate ticket must remain byte-identical. All later progress is recorded only in machine-state and evidence files.
