# C30T pre-AAB Feed action authentication truth matrix

## Founder observation and decision

The founder observed Feed actions entering MoolSocial sign-in and required a
truthful action-by-action audit before another AAB. The founder explicitly
withheld successor AAB authority while authorizing current ticket registration,
audit and source repair.

## Product rule under test

- Public Feed text, plain images, carousels and stable-link sharing are public
  reads and must remain available without MoolSocial sign-in.
- Like, Save, poll/quiz Vote, Message and Create are account-bound writes or
  private state and must require MoolSocial identity.
- An authentication gate must preserve the exact requested post/route and must
  not falsely record the requested interaction before sign-in.
- Reply/Comment and Repost remain separate action-completion capabilities. If
  unavailable or incorrectly gated, each becomes a separately selected repair
  ticket rather than being hidden inside this test-only audit.

## Classification and minimum implementation

This is `mvp_required`: authentication and public-read truth are release gates
for the supported Social launch slice. Existing session, Feed, interaction and
share owners are reused. The minimum implementation is an exhaustive widget
and gateway matrix in the current C30T test owner; no new production owner is
needed.

## Explicit hold

No production source, backend, cloud, Hosting, Play, AAB, upload, install, OPPO,
email or quota action is authorized by this ticket.

## Source audit result

Focused Flutter verification passed `29/29` with zero failures.

Correct current behavior:

- public Feed reading, a plain-image hit area, carousel navigation, Share and
  Copy link remain in the guest-ready state;
- Like, Save, Vote, Message and Create enter MoolSocial authentication;
- the consolidated guest/no-false-write matrix also covers the direct Repost
  button, while successor tests cover Reply submission, Follow, Add thoughts
  and Send in Chat;
- the exact post or Chat-start return route is retained; and
- the interaction gateway receives zero pre-authentication writes.

Verified successor defects:

1. Reply/Comment is visible but ends in “not available” with no composer.
2. Repost is visible but ends in “not available” with no state change.
3. Share exposes Copy link only; Repost/Undo, Add thoughts and Send in Chat are
   absent.
4. Plain post media is public but has no post/media-open completion.
5. Author profile and Follow completion are absent from the public card.

## Successor reconciliation

Each defect above now has its own durable C30T successor ticket and source
implementation. Focused tests pass for Comment/Reply, Repost/Undo and the full
Share sheet, public media opening, and author profile/Follow. All remain marked
`live_Play_acceptance_pending` until a future candidate is separately
authorized, delivered through Google Play, and exercised on the OPPO.

The matrix is source-qualified only. It does not claim live Play acceptance or
authorize another AAB.
