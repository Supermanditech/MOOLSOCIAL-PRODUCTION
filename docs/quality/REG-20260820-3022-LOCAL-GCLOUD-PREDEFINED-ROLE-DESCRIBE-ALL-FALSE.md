# REG-20260820-3022 local gcloud predefined role describe all false

## Incident

Before creating the dedicated public-auth runtime service account, the primary
ran a local read-only preflight for six expected Google predefined IAM roles.
Every role describe returned nonzero with output suppressed, producing no
usable evidence from the local `gcloud` context.

## Impact

- No service account or IAM policy was created or changed.
- No secret, token, account listing or policy body was emitted.
- The all-false local result is rejected as role-existence evidence.

## Root cause

The local `gcloud iam roles describe` context or role identifier form was not
qualified against the authenticated Dev Cloud Shell before relying on exit
codes.

## Prevention

Do not retry the local grouped probe. Use the already authenticated Cloud Shell
to validate one exact role identifier at a time with sanitized booleans, then
create the dedicated service account and apply only validated bindings. Keep
full policies, members, tokens and identifiers out of returned evidence.
