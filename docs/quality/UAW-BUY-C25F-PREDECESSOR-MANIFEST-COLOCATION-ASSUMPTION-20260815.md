# Buy C25F predecessor-manifest co-location assumption

Date: 15 August 2026
Regression: `REG-20260815-2260-BUY-C25F-PREDECESSOR-MANIFEST-COLOCATION-ASSUMPTION`

The read-only Buy audit requested a non-existent C25F-local `RUNTIME-MANIFEST.txt`. The parsed C25F baseline explicitly records the exact manifest at `artifacts/quality/buy-protected-candidate-c24f-connected-back-20260809-02/RUNTIME-MANIFEST.txt`.

No protected file changed. The retry must resolve the complete stored property value rather than assuming that a retained predecessor manifest is co-located with its successor baseline.
