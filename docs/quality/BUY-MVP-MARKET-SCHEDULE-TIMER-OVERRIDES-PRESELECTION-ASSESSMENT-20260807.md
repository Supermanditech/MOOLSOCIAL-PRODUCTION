# Buy market-schedule timer overrides preselection assessment

Date: 7 August 2026
Ticket: `BUY-MVP-MARKET-SCHEDULE-TIMER-OVERRIDES`
Exact actor: Commerce Policy Administrator
Classification: `mvp_supporting`

Customer/operator outcome: an exact authorized Commerce Policy Administrator
can append a future-order timing override for one exact Buy family, scoped by
approved market type, provider type, category, locality, weekday/time band or
declared-busy state. Later server resolution is deterministic and can be frozen
by Ticket 3; this ticket does not mutate an active order.

Production-source search across verified backend, mobile, Admin and web roots
returned zero schedule-override owners. Complete docs/config authority search
returned four exact ticket references. Ticket 1 is locally qualified and owns
the family/timing bounds; SAM-R07 owns authorization, confirmation, optimistic
versioning, fingerprint, retry/conflict and receipt behavior. Disposition is
`reuse` plus `new_necessary_work`: minimally expose Ticket 1's pure timing
derivation and add one pure override aggregate/resolver with colocated tests.

The override selector requires an exact family and at least one qualifier.
Optional qualifiers are stable market-type, provider-type, category and
locality IDs; an ISO weekday/time band evaluated in an exact IANA timezone;
and the exact `declared_busy` workspace signal. Per-user profiling, inferred
busy state and personal-device activity are forbidden. Time bands support
ordinary and cross-midnight intervals. Repeated and skipped civil times use
the runtime's IANA timezone projection, so both repeated DST-equivalent UTC
instants resolve from their actual local weekday/minute without guessing an
offset.

Precedence is deterministic and data independent: higher qualifier count wins;
ties compare the fixed vector declared-busy, weekday/time-band, locality,
category, provider type and market type; an unresolved equal vector overlap is
rejected. Publish returns intersecting override IDs as warnings. Each override
ID has strictly increasing effective revisions. An append-only disabled
revision restores the next eligible override/global policy without rewriting
history; Ticket 5's maker-checker rollback workflow remains excluded.

Coverage includes exact four-family isolation, all selector dimensions,
specificity and tie precedence, overlap/rejection, IANA timezone validation,
Kolkata and DST repeated/skipped-time equivalents, cross-midnight weekday
matching, effective-now/non-backdating, strict per-override order, enable and
disable resolution, SAM-R07 authorization/idempotency/concurrency, immutable
payload-free audit, input nonmutation, focused tests twice and full backend
regression twice.

New screens/routes/stores/endpoints: zero. Excluded: Admin presentation,
persistence, Firebase/API/callable adapter, live tenant/role/schedule/policy,
active-order mutation or snapshot, inferred/personal signals, external
messaging/calling/payment/funds, APK/build/install/OPPO, credentials,
Production, commit, push, deploy and promotion. Local estimate is under one
day and inside the 60–75-day lock.

Pre-write identity: branch
`remediation/prototype-conformance-2026-07-20`, HEAD
`f6dfe7587aa02d782e94282d14af8bafff48ded0`, exact portfolio manifest SHA-256
`5CE81AB6332607A71B960C57A1E99466109E13299CD8A5995FFC3163F35893AF`,
Ticket 1 contract SHA-256
`29CC12139B84D8AAEEED2F37D41740C1C4AB1A6E39759EAF31E224DE262303DC`,
Ticket 1 state SHA-256
`76D35B6101D7D84C78BB39DD54E680C3645CC08815A875FB99F8EDDDD77C95A9`.
Invocation-local long-path Git inventory before this evidence write contained
49,587 entries, UTF-8/LF SHA-256
`AFCD22DD61D9AF29A7026182684A6F8C9DF34C5E41E07FD34341356F3B97994E`,
with zero Git warnings. All pre-existing tracked and untracked files remain
preserved.
