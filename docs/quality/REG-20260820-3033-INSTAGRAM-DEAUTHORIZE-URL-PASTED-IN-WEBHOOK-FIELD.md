# REG-20260820-3033 Instagram deauthorize URL pasted in webhook field

## Incident

On the Instagram API setup page, the founder pasted the deployed Instagram
deauthorization callback into the Step 3 Webhook `Callback URL` field rather
than opening Step 4 `Business login settings`.

## Impact

- The webhook verify token remained empty and `Verify and save` remained
  disabled, so no webhook configuration was saved.
- No callback, provider, secret, token, private login or external runtime state
  changed.
- The field must be cleared before opening the correct business-login modal.

## Root cause

The page exposes both webhook and business-login callback controls in adjacent
sections, and the exact destination field label was not revalidated before
paste.

## Prevention

Never paste a provider callback until the modal title and both exact target
labels are visible. Webhook Callback URL and Verify token stay blank. Only the
Step 4 Business login settings modal may receive OAuth redirect,
deauthorization callback and data-deletion request URLs.
