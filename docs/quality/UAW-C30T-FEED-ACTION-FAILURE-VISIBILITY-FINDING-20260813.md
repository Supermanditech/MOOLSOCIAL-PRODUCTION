# C30T Feed action failure-visibility finding — 2026-08-13

## Findings

1. Like, Save and Vote awaited real provider work and retained failures in the
   generic Shared session, but the active Feed did not render that message. The
   control simply re-enabled after an offline/provider rejection.
2. Repost was visibly enabled but its unsupported result was also stored only
   below the active Feed, so the tap appeared inert.

No action falsely mutated the local post; the defect was missing outcome truth.

## Correction

The session now retains the exact interaction failure by post. Published-content
actions await their authoritative result and display that post's error when the
result is false. Repost remains unsupported and non-mutating but immediately
states that it is unavailable and nothing changed.

## Verification

The complete Create/public-Feed suite passed `13` tests. It proves offline Like
and unsupported Repost messages and re-proves provider timestamps, every public
format, Feed ordering, exact share link, guest Like/Save/Vote authentication,
shared-link pagination, missing-link recovery, draft retention and Create
publication. Evidence SHA-256:
`524BD6583170EED2A594250AFB2080613A0404617CE2EF64F293F91AB6D081E1`.

No Repost/Reply backend was added. No provider deployment, AAB, Play action,
OPPO mutation, Hosting action or external communication occurred.
