# REG-20260820-3031 public invoker blocked by domain-restricted sharing

## Incident

The founder attempted to complete the Dev public-auth deployment by granting
`roles/run.invoker` to `allUsers` on the one underlying Cloud Run service. IAM
rejected the binding because organization policy permits principals only from
an approved customer/domain boundary.

## Impact

- The function remains `ACTIVE` with the qualified runtime identity, parameters
  and secret bindings.
- No public invoker binding was added; the endpoint is not usable by the mobile
  app or Meta callbacks.
- No organization policy, hosting, build, Play, OPPO, email, SMS or private
  login state changed.

## Root cause

Effective domain-restricted-sharing policy forbids the special unauthenticated
principal required for a directly public Cloud Run service.

## Prevention

Do not retry the binding and do not weaken organization policy implicitly.
After refreshed gates, read back only which DRS constraint class is effective,
without allowed customer values. Then require an explicit founder decision
between a narrowly reviewed policy exception and an authenticated public proxy
architecture before any external write.
