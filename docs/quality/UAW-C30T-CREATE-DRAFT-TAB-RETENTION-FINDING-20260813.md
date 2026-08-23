# UAW C30T Create draft tab-retention finding — 2026-08-13

## Finding

The active `SocialCreateWorkbenchV2` owns its caption, format, selected media,
four poll/quiz choices and selected Quiz answer entirely inside its mounted
State. The Social consumer replaces that subtree whenever the user selects
Feed, Home or Shorts. Returning to Create constructs a new empty workbench and
silently loses the unfinished content.

## Bounded correction

Own one in-memory Create draft at the Social consumer lifetime and bind each
workbench mount to it. The draft covers the exact approved text, image,
carousel, Image Poll, Quick Poll and Quiz fields. It is cleared only after an
authoritative publish success. Cloud drafts and cross-device sync remain out of
scope.

No backend, provider, device, build, Play, Hosting, or communication action is
part of this correction.

## Verification

The Create, authenticated gateway and sign-in-boundary focused corpus passed 21
tests with zero failures. The exact log is
`artifacts/quality/uaw-personal-mvp-social-play-internal-live-read-recovery-c30t-continuous-audit-20260813-03/create-draft-retention-focused-tests.log`
with SHA-256
`D5A9A228D9EFAA7096C3957E88735A7241930E1089D045FF611F9FD5045ACD22`.

The exact round-trip test covers text, image, carousel, Image Poll, Quick Poll
and Quiz state, including selected media and the Quiz answer. A release AAB
remains separately founder-gated.
