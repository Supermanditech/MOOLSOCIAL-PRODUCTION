# C30T pre-AAB Feed Comment/Reply dead end

The public Feed renders a Reply action, but `_explainMoolSocialReplyGate`
always states that replies are unavailable and submits nothing. This conflicts
with the supported Feed contract requiring comments to open in place and Back
to restore the originating item.

This `mvp_required` successor will reuse the current Social sheet, session,
content gateway/function and Firestore store. Public comment reading remains
guest-accessible; writing requires MoolSocial identity and exact post return.
Only validated text replies, server-acknowledged counts, retained drafts and
offline/rejected/retry recovery are in scope. Nested threads, mentions,
reactions, edit/delete, notifications, moderation UI, deployment and another
AAB are excluded.

## Source implementation result — 2026-08-13

- Reply now opens the existing Social sheet and loads exact-post public
  comments without requiring MoolSocial identity.
- Only reply creation enters the real sign-in gate, with the exact Feed item as
  the success return. Cancelling sign-in or closing/reopening the sheet retains
  the bounded draft.
- Signed-in replies are trimmed and limited to 1–500 characters. UI comment
  insertion and reply-count changes occur only from the server acknowledgement;
  there is no optimistic success claim.
- Offline, rejected and timeout outcomes preserve the draft and retry identity.
  Transactional backend idempotency creates one comment and increments once.
- Public comment pages and reply acknowledgements are rejected if their post
  identity differs from the exact requested Feed item.
- No new route, route-level screen or backend owner was added.

Qualification evidence:

- focused Flutter set: 50 passed, 0 failed;
- backend `npm run verify`: 512 passed, 0 failed;
- Flutter analyzer: all 8 exact owned Dart/test items clean.

State is
`source_implemented_focused_tests_passed_live_Play_acceptance_pending`.
No backend deployment, AAB build/upload/install, device write or external-
service write is authorized or performed.
