# UAW C30U post-cycle-1 unverified cycle JSON property assertion

Date: 2026-08-14

## Incident

C30U cycle 1 attempt 8 passed at 1,144 source owners with fingerprint
`E37EBB01BF0D46379FDDF7B04F0D1002C3DE62DD894B53A8C5A5A6CCFAF4E352`,
Flutter 405 plus three declared skips, backend 516, Hosting 7 and mutation
counts 0/0/0.

A subsequent read-only combined seal projection used an unverified property
name from the cycle JSON and rejected its own opaque assertion. That projection
is zero evidence.

## Consequence and prevention

This mandatory registration changes regression memory, which is itself a
source-manifest owner. The passing attempt-8 cycle is therefore preserved but
superseded and cannot authorize a build. Enumerate the exact cycle schema,
validate named scalars separately, version the accepted manifest/cycle evidence
owners, reset the machine cycle count to zero and run two fresh identical
cycles. No source or memory writes are permitted between those two cycles.

The exact current cycle schema was enumerated. Its source fingerprint property
is `sourceManifestSha256`; the rejected projection had used an unverified name.
Attempt 8 is preserved at SHA-256
`F59B833F3E7F4738141DF10C566041D2C685F5CFE2AB891740C39AFCE8462830`.
Both machine-state owners now record it as superseded, expose zero current
qualifying cycles and retain build/upload/install counts at 0/0/0. Fresh
evidence uses accepted manifest v3 and cycle JSON v2 owner names.

No AAB, Play or OPPO mutation occurred.
