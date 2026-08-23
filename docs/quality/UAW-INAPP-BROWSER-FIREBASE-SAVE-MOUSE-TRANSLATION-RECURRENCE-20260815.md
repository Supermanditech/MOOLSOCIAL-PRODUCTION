# In-app browser Firebase Save mouse-translation recurrence

- Regression: `REG-20260815-2461-INAPP-BROWSER-FIREBASE-SAVE-MOUSE-TRANSLATION-RECURRENCE`
- Failure: a fresh DOM snapshot and reacquired visible enabled Save locator still translated to a point where the in-app browser found no element.
- Impact: Firebase remained unsaved; no provider configuration changed.
- Prevention: block further mouse retries for this dialog and use a supported keyboard or viewport-safe submit path, followed by provider-table verification.
