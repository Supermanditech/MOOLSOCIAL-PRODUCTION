# C30Q Play hidden AAB input forced-click rejection

Date: 2026-08-12

## Mistake

After confirming the first Play file input accepted `.aab`, the recovery attempt tried to force-click that hidden input. Chrome's supported locator bridge still required a visible match and rejected the click before it opened a chooser.

## Impact

- No file was selected or uploaded.
- The Internal Testing draft remained zero-bundle.
- No repository artifact, machine state, device state, credential, or secret changed.

## Permanent prevention

Do not force-click Play's intentionally hidden file input. With Chrome file-URL access enabled, arm a handled chooser wait and activate the visible Upload button associated with the `.aab` input; handle both click and chooser failures inside the browser execution call.
