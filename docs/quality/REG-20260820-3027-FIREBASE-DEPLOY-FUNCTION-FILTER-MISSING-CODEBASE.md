# REG-20260820-3027 Firebase deploy function filter missing codebase

## Incident

After successful Firebase reauthentication and authoritative proof that the Dev
function did not exist, the founder retried deployment with
`functions:moolSocialPublicAuth`. The predeploy build passed, but Firebase CLI
reported that no function matched the filter and aborted before runtime
parameter entry.

## Impact

- No public client ID or redirect was entered.
- No function or external runtime state changed.
- The backend build passed but is not deployment evidence.

## Root cause

The repository declares the Functions codebase as `provider`; the deployment
filter omitted that codebase qualifier.

## Prevention

Do not retry the unqualified filter. Validate the installed CLI's exact
codebase-qualified syntax from local help/config, then deploy only
`provider:moolSocialPublicAuth`, retaining the Dev project and all held release
actions.
