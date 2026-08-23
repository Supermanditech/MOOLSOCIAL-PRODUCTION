# UAW C33E protected Social action intent collapses after authentication

Date: 2026-08-15
Regression: `REG-20260815-2349-C33E-PROTECTED-SOCIAL-ACTION-INTENT-COLLAPSES-AFTER-AUTH`

## Observed defect

The signed-out Feed correctly blocks protected writes, but Like, Save, Repost, Reply and Poll vote all use one item-only authentication return URI. After identity succeeds the client can recover the Feed item but cannot determine which protected action the customer requested. Existing C30T coverage explicitly accepts the same item-only route for Like, Save and Repost, so the defect escaped source qualification.

## Source evidence

- `SocialPublishedContentCardV2` accepts one `VoidCallback? onAuthenticationRequired` and passes it to both the poll and action-row owners.
- `_PublicPoll._vote` drops the selected choice when it calls that callback.
- `_PublicActionRow._runAuthenticated` drops whether Like, Save or Repost triggered authentication.
- `SocialUniversalV2._requireFeedAuthentication` records only `sub=feed&item=<id>`.
- `JourneyRouter` passes `state` and `item` into Social V2 but has no protected-action intent parameter.

## Required recovery

Select a bounded MVP-required authentication-continuity ticket. Reuse the existing Social route, card, session and gateway owners; preserve exact action metadata without adding a screen, route, backend or provider; never auto-replay a toggle or vote from a persistent URL; and add negative coverage for malformed/stale intent plus exact signed-out cancellation and signed-in return behavior.

Build, Play, OPPO, provider, secret, email and quota actions remain held.
