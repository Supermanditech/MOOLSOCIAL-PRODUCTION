# REG-20260820-3023 Facebook App Secret revealed screenshot rotation required

## Incident

While preparing the founder-only Facebook App Secret for Secret Manager, a
screenshot was returned with the App Secret field in a revealed or selected
state. Codex does not retain or repeat the value, but the current secret must be
treated as potentially exposed.

## Impact

- The Facebook callback function is not deployed and no live integration uses
  the current secret.
- No Facebook secret version was added to Secret Manager from this value.
- The value is not recorded in repository evidence.
- The secret must be reset before provider configuration continues.

## Root cause

Visual readback was requested after opening a founder-only credential surface
instead of requiring the provider page to be re-hidden before any screenshot or
chat interaction.

## Prevention

Never capture or return a screen while a provider secret is revealed. After
this incident, reset the unused Facebook App Secret, copy the rotated value
directly into a pre-waiting hidden Cloud Shell prompt, re-hide it, and return
only the literal Secret Manager version marker. No screenshot is accepted as
credential evidence.

## Founder clarification

The founder confirmed that the screenshot was redacted before sharing and the
secret value was not exposed. Rotation is therefore not required. The current
value may be copied directly into the waiting hidden Cloud Shell prompt; no
credential value is accepted into chat or repository evidence.
