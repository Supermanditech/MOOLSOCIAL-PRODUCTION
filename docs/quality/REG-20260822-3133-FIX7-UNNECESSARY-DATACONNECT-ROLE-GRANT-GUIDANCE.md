# REG-20260822-3133 — unnecessary Data Connect role-grant guidance

Date: 22 August 2026

State: registered before any IAM mutation

Codex asked the founder to add Firebase Data Connect API Admin and Cloud SQL
Admin to the active Dev deployment principal after a direct-member gcloud
projection showed none of those named roles. The founder's current Dev IAM
screenshot then proved that the intended human administrator already has the
project Owner role. The official Data Connect role reference includes Owner on
the required service, schema and connector permissions, so the requested
additional grants were unnecessary.

The founder did not apply the suggested grants. No IAM binding, Data Connect
deploy, schema migration, function deploy, Hosting deploy, secret payload read,
build, Play action, OPPO action, email or SMS occurred. All FIX7 deployment
mutation counts remain zero.

Root cause: the direct-member projection did not resolve whether gcloud's
active principal matched the Firebase/Console principal or whether access was
inherited, and Codex converted that incomplete observation into role-change
guidance.

Prevention: never request an IAM grant from a direct-binding projection alone.
First inspect the current authoritative Console row or a complete effective
permission result, account for inherited Owner/Admin access and ask only for a
read-only Policy Troubleshooter result when permission truth remains unclear.
