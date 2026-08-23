# REG-20260820-3018 Email Link continue `/app` live 404

## Incident

After confirming Firebase passwordless Email Link and the public authorized
domain, the primary performed a bounded live validation of the qualified
Android continuation path. `https://moolsocial.com/app` returned HTTP 404 with
no redirect, while the exact public Android App Links association returned HTTP
200 on the same host.

## Impact

- No live email was sent and no private link or address was entered.
- No provider, hosting, deployment, build, Play or OPPO state changed.
- The public domain association exists, but users without a successful app-link
  handoff would receive a broken continuation fallback.
- `continueUrlQualified` must remain false until source, authorized hosting
  deployment and live readback all pass.

## Root cause

The mobile runtime and Android intent filter accept secure `/app` paths, but the
current public hosting source/deployment does not serve a fallback at `/app`.

## Prevention

Do not guess another continuation URL. Add one minimal public `/app` fallback
source under the existing website, verify it locally without sending email, and
keep hosting deployment blocked until a separate action-time founder
authorization. After deployment, require live 200, unchanged asset association,
exact release defines and one separately authorized real-email OPPO journey.

## Resolution

After explicit action-time founder authorization, the tested Hosting source was
deployed without any mobile build or email send. The custom `/app` path and the
default Hosting `/app` path both returned HTTP 200, the public App Links
association remained HTTP 200, and the noindex fallback copy matched the locked
source. Real Email Link delivery and OPPO acceptance remain separate gates.
