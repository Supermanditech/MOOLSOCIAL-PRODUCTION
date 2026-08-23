# REG-20260820-3045 Meta official documentation direct fetch HTTP 429

## Observed failure

Two read-only direct fetches to official Meta developer documentation returned
HTTP 429. No content was accepted and no retry or alternate scraping occurred.

## Root cause

Meta rate-limited the external documentation fetch surface.

## Impact

- no repository, provider-console, account, build, Play, OPPO or device state
  changed;
- no private session or credential material was transmitted;
- no Meta documentation claim was added from the failed fetches.

## Prevention and authorized continuation

Do not retry or bypass the rate limit. Retain already captured provider-console
readbacks and require a later signed-in-console readback or official document
fetch only after the provider surface is available normally.
