# REG-20260821-3129 — FIX7 Hosting site readback schema mismatch

Date: 21 August 2026

State: registered; zero cloud mutation

The authorized Firebase Hosting site-list read for exactly
`moolsocial-dev-503018` returned exit code `0` and exactly one result, but the
bounded projection assumed `site`, `name` or `type` fields that were not
present at those paths. It emitted one blank site identity. That output is
semantically incomplete and is not accepted as Hosting-state evidence.

No Hosting deploy, Data Connect deploy, schema migration, IAM binding,
function deploy, secret access, build, Play action, OPPO action, email or SMS
occurred. All FIX7 deployment mutation counts remain zero.

Root cause: the readback projected remembered field names without first
enumerating the installed Firebase CLI result schema.

Prevention: after registration and gate replay, enumerate only the one result
object's property names, then author a bounded projection from those returned
names. Do not infer site identity or deployment readiness from exit code alone.
