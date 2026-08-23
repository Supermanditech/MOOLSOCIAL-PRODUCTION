# C30F resumed-activity colon-literal assumption rejection

- Regression: `REG-20260812-1378-C30F-RESUMED-ACTIVITY-COLON-LITERAL-ASSUMPTION-REJECTION`
- Date: 2026-08-12
- Rejected assumption: the OPPO activity dump would emit a line matching the literal `mResumedActivity:`.
- Consequence: the first-native-bounds formatter stopped before parsing; the original untapped hierarchy and screenshot remain unchanged.
- Prevention: inventory only bounded `ResumedActivity`/`topResumedActivity` lines without punctuation assumptions, select the exact MoolSocial package, and reuse the first hierarchy without relaunch or taps.
