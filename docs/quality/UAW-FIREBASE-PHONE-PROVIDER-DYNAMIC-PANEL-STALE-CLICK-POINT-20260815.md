# Firebase Phone provider dynamic-panel stale click-point regression

- Regression: `REG-20260815-2458-FIREBASE-PHONE-PROVIDER-DYNAMIC-PANEL-STALE-CLICK-POINT`
- Failure: a composite browser action toggled the Phone provider and immediately clicked the test-number panel using a position invalidated by the switch-driven layout update.
- Impact: the panel did not open and the provider configuration was not saved.
- Prevention: collect a fresh DOM snapshot and switch state after each Firebase console mutation before performing the next semantic action.
