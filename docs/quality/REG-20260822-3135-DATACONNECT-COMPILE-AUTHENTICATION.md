# REG-20260822-3135 — Data Connect compile authentication failure

Date: 22 August 2026

State: registered; zero cloud mutation

After the founder's console readback proved that Dev SQL Connect remains on
the unprovisioned `Get started` landing page, the exact repository-owned
compile command was run for service `moolsocial-core` in `asia-south1`. It
returned exit code `1`, JSON `status=error` and the bounded classifier reported
authentication. No compile success or live service state was inferred.

No SQL Connect service, Cloud SQL instance, schema migration, connector, IAM
binding, function revision, Hosting release, secret payload, build, Play action,
OPPO action, email or SMS was created or changed.

Root cause: the installed Firebase Data Connect compile surface could not
complete before the Dev project was initialized for SQL Connect, and its small
error was not yet classified beyond the safe authentication category.

Prevention: do not retry compile or click through a creation confirmation.
Ask the founder immediately to open `Get started` only far enough to expose the
service/database setup choices, retain zero mutations and inspect that next
screen before deciding the exact authorized creation path.
