# C30T pre-AAB Feed author profile and Follow missing

The public Feed card renders author identity as static text and provides no
public author completion or Follow/Unfollow action. This leaves the supported
Feed profile/Follow capability absent.

This `mvp_required` successor reuses the public card, native Social sheet,
content/session owners and current content backend. Public identity remains
guest-readable; Follow/Unfollow requires MoolSocial identity and server
acknowledgement. Profile editing, private fields, follower lists, block/report,
notifications, recommendations, new routes/screens, deployment and another AAB
are excluded.

## Source implementation result — 2026-08-13

- Author avatar, name and handle are now one accessible public tap target. A
  native Social sheet exposes only the exact author's public name, handle,
  follower count and bounded public-post summaries; private profile fields and
  follower lists remain outside the contract.
- Follow and Unfollow require real MoolSocial identity and preserve the exact
  author return through sign-in. Relationship state and follower totals change
  only from server acknowledgement; no optimistic success is shown.
- Offline and rejected outcomes remain truthful and retryable. The backend
  rejects self-follow, cross-author responses and duplicate relationship/count
  changes through an idempotent transaction.
- A real-author Feed card and the author sheet now fit the 320x568 compact
  viewport at 140-percent text. The five Feed actions use equal bounded slots,
  preserving every semantic label, key and tap while preventing enlarged
  `Repost` or other labels from overflowing.
- No new route, route-level screen or backend owner was added.

Qualification evidence:

- focused Flutter set: 59 passed, 0 failed;
- complete backend typecheck/build/bounded replay: 516 passed, 0 failed;
- Flutter analyzer: all 8 exact owned Dart/test items clean.

State is
`source_implemented_focused_tests_passed_live_Play_acceptance_pending`.
No backend deployment, AAB build/upload/install, device write or external-
service write is authorized or performed.
