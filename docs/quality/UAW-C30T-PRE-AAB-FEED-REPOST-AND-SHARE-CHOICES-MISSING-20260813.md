# C30T pre-AAB Feed Repost and Share choices missing

The current Repost control always rejects with “not available,” and the Share
sheet contains only Copy link. The supported Feed sharing contract also owns
Repost/Undo, Add thoughts and Send in Chat.

This `mvp_required` successor keeps Copy link public, requires MoolSocial
identity for account-bound choices, reuses the current content interaction
owner for Repost/Undo, reuses the Post composer for quoted thoughts and opens
existing Chat with exact post context. Chat must never send automatically.
External sharing SDKs, contact pickers, new routes/screens/backends, deployment
and another AAB are excluded.

## Source implementation result — 2026-08-13

- Copy link remains a public read action and copies the exact stable Feed URL.
- Guest Repost, Add thoughts and Send in Chat enter the real MoolSocial sign-in
  gate with exact success and cancellation returns; no interaction is guessed.
- Repost and Undo now use the existing single-flight content interaction owner
  and update UI only after the server-acknowledged post record returns.
- Add thoughts reuses the current Post composer and publishes a structured,
  server-resolved snapshot of the exact still-public original post. Empty
  thoughts are rejected before any write.
- The post-sign-in `shared-post` return resolves paginated Feed truth and
  restores the exact quote without losing or inventing draft content.
- Send in Chat reuses existing Chat navigation, prefills the stable post link,
  preserves recipient choice and never sends automatically.
- No new route, route-level screen or backend owner was added.

Qualification evidence:

- focused Flutter set: 48 passed, 0 failed;
- backend `npm run verify`: 508 passed, 0 failed;
- Flutter analyzer: all 15 exact owned Dart/test items clean.

State is
`source_implemented_focused_tests_passed_live_Play_acceptance_pending`.
No backend deployment, AAB build/upload/install, device write, Chat send or
external-service write is authorized or performed.
