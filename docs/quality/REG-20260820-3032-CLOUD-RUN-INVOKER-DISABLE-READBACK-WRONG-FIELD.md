# REG-20260820-3032 Cloud Run invoker-disable readback used wrong field

## Incident

Cloud Shell successfully completed the service-scoped Cloud Run update with
`--no-invoker-iam-check`, and the service read back Ready. The sanitized JSON
projection then tested a top-level `invokerIamDisabled` field that was absent in
the `gcloud run services describe` representation, producing `false` rather
than authoritative access-state evidence.

## Impact

- The update command succeeded and a new Ready service revision/configuration
  was applied.
- The invoker-check state remains unqualified until the correct documented
  annotation/field and an unauthenticated HTTP rejection test both pass.
- No second update, invocation, build, Play, OPPO, email, SMS or private login
  occurred.

## Root cause

The readback assumed the Cloud Run v2 API field shape instead of the installed
`gcloud` service-description representation used by the update command.

## Prevention

Do not rerun the update. Read only the documented invoker-check annotation or
field through a bounded boolean projection, then perform status-only public
HTTP tests proving the request reaches application validation without exposing
the service URL.
