# C30N first-launch hierarchy/screenshot state-mismatch false rejection

- ID: `REG-20260812-1474-C30N-FIRST-LAUNCH-HIERARCHY-SCREENSHOT-STATE-MISMATCH-FALSE-REJECTION`
- Date: 2026-08-12
- Scope: OPPO r60.40 first-native C28D qualification
- Result: first measurement rejected as unstable; no tap, content write, second build or second install occurred

The first no-tap hierarchy described Shop Home and exposed a 21-logical-pixel
search action, but the immediately following screenshot showed the retained
product-detail route. The app was still restoring state between the sequential
captures, so the hierarchy and bitmap did not prove one stable visible frame.
C30N preserves both files, withdraws the premature device rejection and takes
two new no-tap capture pairs only after their route and semantic summaries are
stable. C28D disposition uses only matching-state evidence.
