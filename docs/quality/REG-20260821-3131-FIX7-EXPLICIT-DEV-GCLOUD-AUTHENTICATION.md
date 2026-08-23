# REG-20260821-3131 — FIX7 explicit-Dev gcloud authentication failure

Date: 21 August 2026

State: registered; zero cloud mutation

After the default-project mismatch was registered and all three gates were
replayed at registry generation 3101, gcloud was invoked with the explicit
project `moolsocial-dev-503018` to read only project identity and lifecycle.
The command returned exit code `1` and the bounded classifier identified an
authentication failure. No account, token, credential value, login URL or raw
diagnostic was emitted.

No secret IAM policy was read or changed. No Data Connect deploy, schema
migration, IAM binding, function deploy, Hosting deploy, secret payload read,
build, Play action, OPPO action, email or SMS occurred. All FIX7 deployment
mutation counts remain zero.

Root cause: the installed gcloud credential context cannot currently authorize
even the explicit-Dev project metadata read.

Prevention: do not retry, obtain tokens, import credentials or run gcloud IAM
commands. Require a founder-controlled gcloud authentication checkpoint, keep
every later command explicitly scoped to `moolsocial-dev-503018`, and replay
all three gates before one new read-only project preflight. Data Connect's
separate HTTP 403 permission blocker must also be resolved before deployment.
