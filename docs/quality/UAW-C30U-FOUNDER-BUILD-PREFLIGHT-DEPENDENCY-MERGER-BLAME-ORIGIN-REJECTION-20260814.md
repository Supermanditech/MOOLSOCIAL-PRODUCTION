# UAW C30U founder build preflight dependency merger-blame origin rejection

Date: 2026-08-14

## Incident

The founder-only C30U launcher accepted the two hidden inputs and the C30U AAB
state gate passed `Phase build` with counts 0/0/0. Before invoking the actual
App Bundle build, `scripts/invoke-play-internal-aab-build-c30t.ps1` failed
closed with:

`C30T single AAB build rejected: exported dependency-component merger-blame origin changed.`

The terminal returned to its prompt. No AAB success was recorded, no upload or
install occurred, and no second build is authorized or attempted.

## Required diagnosis

First prove machine-state build count remains zero, authority remains available
and founder-qualified transient flags were cleared by the launcher. Then read
only the exact wrapper assertion and its bounded generated merger-blame lines.
Do not weaken manifest provenance. If the expected origin is historical debt,
replace it only with an exact current release provenance assertion; if the
origin is genuinely wrong, repair the production manifest owner.

Any durable change invalidates the prior source seal and requires two fresh
identical cycles before the founder launcher can be shown again.

## Exact diagnosis

The generated release merger-blame proves:

- `GenericIdpActivity` → `firebase-auth:24.1.0`
- `RecaptchaActivity` → `firebase-auth:24.1.0`
- `RevocationBoundService` → `play-services-auth:21.6.0`
- `ProfileInstallReceiver` → `profileinstaller:1.4.0`

The exported component and exported flag did not change. Only the historical
`play-services-auth:20.7.0` provenance literal was stale. The wrapper now
requires exact 21.6.0 provenance, and the C30U static wrapper gate rejects both
absence of 21.6.0 and reintroduction of 20.7.0.

The static C30U wrapper gate passes, and a bounded read-only replay of the
generated release merger-blame passes all four exact origins. Build authority
remains available once, the build state remains not started, founder-qualified
flags were cleared and counts remain 0/0/0.
