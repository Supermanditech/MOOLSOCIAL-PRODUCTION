# C30Q Play upload button file-chooser timeout rejection

Date: 2026-08-12

## Mistake

The first Play Console upload attempt armed the supported file-chooser wait and clicked the visible Upload button, but the Chrome bridge did not surface a chooser within its effective three-second window. The asynchronous waiter rejected and reset the browser-control session before any file was selected.

## Impact

- The C30Q AAB was not selected or transmitted.
- Play still had no uploaded release artifact from this attempt.
- No repository artifact, machine state, device state, credential, or secret changed.

## Permanent prevention

After reconnecting, read the Chrome file-upload troubleshooting guidance, re-inspect the live release form, and use only its supported recovery flow. Handle chooser waits so a timeout cannot escape as an unhandled rejection, and verify visible upload state before any further release action.
