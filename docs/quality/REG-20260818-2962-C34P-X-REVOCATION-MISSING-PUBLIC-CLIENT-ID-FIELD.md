# REG-20260818-2962 C34P X revocation missing public-client ID field

Date: 18 August 2026 (IST)
State: registered before contract and test strengthening

## Incident

After the corrected X suite passed 12/12, primary source review found that
`XRevocationRequestDescription.requiredFormFields` listed only `token`.
Official X OAuth 2.0 public-client revocation requires both the token and the
public `client_id`. The source correctly forbids a client secret, but the passed
test did not assert the required public-client field, so the pass is incomplete
for the founder's exact revocation contract.

No network, browser, provider, device, private, account, build or external
action occurred.

## Root cause

Revocation coverage asserted method, content type, endpoint and absence of a
client secret but omitted the complete required form-field inventory.

## Prevention

Add `client_id` to the exact revocation required-field description and assert
the complete two-field set plus continued absence of client-secret execution or
credential persistence. Reformat and clean-analyze both X owners, then run one
new primary-authorized serialized focused test. The earlier 12/12 pass remains
preserved but is superseded by the strengthened run.

## Retained evidence

- `apps/mobile/lib/core/auth/x_oauth2_pkce.dart`
- `apps/mobile/test/uaw_c34p_x_oauth2_pkce_test.dart`
- `config/codex-development-regression-registry.json`
- this incident record
