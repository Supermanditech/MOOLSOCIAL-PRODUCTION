# In-app browser Firebase Save Space activation no-op

- Regression: `REG-20260815-2465-INAPP-BROWSER-SAVE-SPACE-ACTIVATION-NOOP`
- Failure: Space dispatched to the enabled Save locator but did not submit the dialog.
- Detection: the authoritative provider table still showed Phone Disabled and the dialog remained open.
- Impact: no Firebase state changed; the approved fictional pair remains staged.
- Prevention: stop browser automation retries for this Save control and request exactly one founder click, then re-read the authoritative provider table before recording success.
