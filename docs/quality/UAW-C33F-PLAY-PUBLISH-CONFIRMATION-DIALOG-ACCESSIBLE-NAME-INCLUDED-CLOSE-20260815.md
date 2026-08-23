# UAW-C33F Play publish confirmation dialog accessible name included Close

Date: 2026-08-15

## Preserved mistake

The first final Internal Testing confirmation attempted to scope the confirmation button through a dialog named exactly `Publish change on Google Play?`. Play Console exposed the dialog's accessible name as `Publish change on Google Play? Close`, so the dialog locator matched nothing and no publish action executed.

The modal remained open, the exact r60.49 release remained ready but unpublished, and no second upload or other-track action occurred.

## Prevention

Register before retry. After opening a dynamic confirmation modal, reacquire a fresh DOM snapshot and use the unique visible active confirmation button when the dialog's accessible name incorporates descendant control text. Verify that exactly one visible active `Save and publish` button exists inside the modal state before clicking once, then verify the Internal Testing release page and version.
