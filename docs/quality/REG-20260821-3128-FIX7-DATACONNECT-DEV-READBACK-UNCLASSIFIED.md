# REG-20260821-3128 — FIX7 Data Connect Dev readback unclassified failure

Date: 21 August 2026

State: registered; HTTP 403 reason classification pending; zero cloud mutation

After founder-controlled Firebase reauthentication and a complete regression,
coordination and MVP gate replay at registry generation 3098, the one newly
authorized non-interactive Data Connect service-list readback for exactly
`moolsocial-dev-503018` returned exit code `1`. The initial bounded classifier
reported only `other`. After registration and gate replay, one bounded
diagnostic established HTTP `403`, but its classifier matched the status code
before inspecting the provider's machine-readable error reason. The founder's
authoritative Policy Troubleshooter result now proves that an IAM Allow policy
permits `firebasedataconnect.services.list`; overall access remains Unknown
only because deny and principal-access-boundary policies were not visible.
Raw output remained suppressed and contained no Google login URL.

No Data Connect deploy, schema migration, IAM binding, function deploy,
Hosting deploy, secret access, alternate credential use, provider login,
build, Play action, OPPO action, email or SMS occurred. All FIX7 deployment
mutation counts remain zero.

Root cause: the wrapper classified every HTTP `403` as permission denial before
checking structured reasons such as service-disabled, billing, quota or policy
denial. The status code alone did not establish missing IAM allow access.

Prevention: do not request IAM changes or infer absent service state from HTTP
status alone. After gate replay, parse and emit only the structured error code,
status and reason allowlist from one read-only Firebase CLI result, keeping
messages, identities and login material suppressed. Deployment remains held
until the exact reason and safe schema diff are authoritative.
