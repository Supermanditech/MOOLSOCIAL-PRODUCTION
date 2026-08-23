# C22F InkWell press-timeout test rejection — 2026-08-08

The selected-emission token and six family widget cases passed. The local/main press cases sampled immediately after `startGesture`, before InkWell dispatched `onHighlightChanged`, so target opacity remained zero. REG-20260808-545 requires holding through the framework press timeout before reading the 100 ms emission state.
