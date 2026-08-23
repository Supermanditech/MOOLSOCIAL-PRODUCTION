# In-app browser locator press did not activate Firebase Save

- Regression: `REG-20260815-2462-INAPP-BROWSER-LOCATOR-PRESS-DID-NOT-ACTIVATE-SAVE`
- Failure: locator `press("Enter")` returned without error but did not submit the Firebase Phone provider dialog.
- Detection: the dialog remained open and the authoritative provider table still showed Phone Disabled.
- Impact: no Firebase configuration changed.
- Prevention: external-service success requires authoritative post-action state; use the enabled Save element's supported DOM click path when translated mouse input and locator press are ineffective.
