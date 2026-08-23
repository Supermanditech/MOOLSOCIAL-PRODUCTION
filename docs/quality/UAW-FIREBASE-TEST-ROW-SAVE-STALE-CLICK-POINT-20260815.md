# Firebase test-row Save stale click-point regression

- Regression: `REG-20260815-2460-FIREBASE-TEST-ROW-SAVE-STALE-CLICK-POINT`
- Failure: after the approved fictional test row was inserted, Firebase moved the dialog and the first Save click was rejected at the stale translated point.
- Impact: the Phone provider configuration remained unsaved; the correctly staged fictional row remained in the open dialog.
- Prevention: after every Firebase inline-row insertion or deletion, collect a fresh DOM snapshot and reacquire Save in a separate action before clicking, then verify the provider table state.
