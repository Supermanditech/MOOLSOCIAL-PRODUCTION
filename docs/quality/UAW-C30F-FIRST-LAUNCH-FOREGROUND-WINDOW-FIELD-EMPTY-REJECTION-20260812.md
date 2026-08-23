# C30F first-launch foreground window-field empty rejection

- Regression: `REG-20260812-1377-C30F-FIRST-LAUNCH-FOREGROUND-WINDOW-FIELD-EMPTY-REJECTION`
- Date: 2026-08-12
- Observation: `dumpsys window windows` emitted neither `mCurrentFocus` nor `mFocusedApp`, so the bounded foreground value was null.
- Preserved untapped evidence: `07-first-launch.xml` SHA-256 `DF3A256AA64E7E3037A3E2679099F62D3D93C7791BDD9A7B85777C1D2F193C43`; screenshot SHA-256 `DF80CE327F4318F027E3F650883D110CA4CF7E9B5EC1161F791CB63669E2B4D5`.
- Prevention: use the OPPO ActivityTaskManager `mResumedActivity` field without relaunching or interacting, then combine it with the already captured first hierarchy.
