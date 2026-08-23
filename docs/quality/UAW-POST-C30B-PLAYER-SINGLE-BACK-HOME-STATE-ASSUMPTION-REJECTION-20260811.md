# Post-C30B player single-Back Home-state assumption rejection

- Regression: `REG-20260811-1362-POST-C30B-PLAYER-SINGLE-BACK-HOME-STATE-ASSUMPTION-REJECTION`
- Date: 2026-08-11
- Failure: one Back from active embedded playback was assumed to expose Home/Shorts navigation before the resulting state was identified.
- Prevention: inspect each fresh post-Back hierarchy first and use only actions proven present.
