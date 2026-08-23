# REG-20260821-3130 — FIX7 gcloud default-project mismatch

Date: 21 August 2026

State: registered; zero cloud mutation

The bounded gcloud preflight read its saved default project without reading an
account or access token. The command exited `0`, but the value was not exactly
`moolsocial-dev-503018`. The non-Dev value was intentionally not emitted.

No secret IAM policy was read or changed. No Data Connect deploy, schema
migration, IAM binding, function deploy, Hosting deploy, secret payload read,
build, Play action, OPPO action, email or SMS occurred. All FIX7 deployment
mutation counts remain zero.

Root cause: the installed gcloud configuration is not bound by default to the
authorized Dev project, so an unqualified command could target another context.

Prevention: never mutate or trust that default for FIX7. After registration
and gate replay, every permitted gcloud read must carry the explicit project
`moolsocial-dev-503018` and independently verify the returned resource project
before it can influence an IAM decision. No IAM write may proceed while Data
Connect remains permission-blocked.
