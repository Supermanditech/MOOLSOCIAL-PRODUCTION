# REG-20260822-3132 — FIX7 IAM Troubleshooter authentication failure

Date: 22 August 2026

State: registered; zero cloud mutation

After founder-controlled gcloud login, exact Dev project identity and lifecycle
readback passed. Project IAM policy readback also passed without emitting any
member identity. The subsequent read-only IAM Policy Troubleshooter request for
`firebasedataconnect.services.list` returned exit code `1`, and the bounded
classifier identified authentication failure. No principal, token, credential,
login URL or raw diagnostic was emitted.

No Data Connect deploy, schema migration, IAM binding, function deploy,
Hosting deploy, secret payload read, build, Play action, OPPO action, email or
SMS occurred. All FIX7 deployment mutation counts remain zero.

Root cause: the authenticated gcloud project surface does not provide a usable
credential/quota context for the Policy Troubleshooter command, so that command
cannot establish the active principal's effective Data Connect permission.

Prevention: do not retry, print tokens, use application-default credentials or
infer permission from project visibility. Ask the founder immediately for the
smallest exact external IAM action. Require the active Dev deployment principal
to receive the official Firebase SQL Connect API Admin and Cloud SQL Admin
roles before a new gated Data Connect readback/deploy attempt.
