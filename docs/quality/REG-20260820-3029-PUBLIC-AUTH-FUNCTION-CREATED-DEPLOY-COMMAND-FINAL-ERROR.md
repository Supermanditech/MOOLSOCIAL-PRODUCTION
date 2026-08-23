# REG-20260820-3029 public-auth function created but deploy command ended in error

## Incident

Bounded marker inspection of the codebase-qualified Firebase deployment output
confirmed that runtime parameters were saved and the Gen2
`moolSocialPublicAuth` create operation succeeded. The overall command did not
emit `Deploy complete` and contained a later error.

## Impact

- External Dev state changed: the function create operation succeeded.
- The function URL was emitted by Firebase CLI but is not retained here.
- No invocation, private login, email, SMS, build, Play or OPPO action occurred.
- Deployment cannot be marked complete until the final error is classified and
  authoritative function/runtime/IAM readback passes.

## Root cause

The exact post-create failure is intentionally unclassified until this incident
is registered; success was incorrectly summarized from mixed terminal history
without isolating the final command tail.

## Prevention

Do not retry or invoke. After refreshed gates, classify only the final error
category without emitting URLs or identifiers, then read back function state,
runtime service account, secret bindings and public invocation IAM before any
provider callback save.

## Post-registration classification

Bounded final-command inspection confirms one post-create failure class: the
Firebase CLI failed while setting the function's invoker IAM policy. It did not
report service-account, runtime-secret, parameter, quota or billing failure.
The next action is read-only Gen2 function and invoker-policy readback; the
deployment command must not be rerun.
