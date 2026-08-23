# C30O Play Cloud-project nested-dialog close strict-mode rejection

Date: 2026-08-12

## Observed mistake

After opening the existing-project selector, a generic `Close` button locator was used before reloading the Play Integrity settings page. Two visible dialogs each exposed a Close button, so strict mode rejected the click.

## Root cause

The close action was not scoped to the nested `Existing Google Cloud` dialog that the immediately preceding action had opened.

## Prevention

- Do not repeat an unscoped Close locator while nested dialogs are present.
- Scope the first close to the exact `Existing Google Cloud` dialog, then close or discard the parent `Link Google Cloud project` dialog only after a fresh snapshot proves one target.
- Treat the strict-mode rejection as no external write.

## Retained evidence

The Browser tool result retained both matched dialog descriptions and confirmed that no click was executed.
