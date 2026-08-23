# UAW C30T guest Create-rail sign-in finding — 2026-08-13

## Finding

The Feed `Create a post` CTA and creation gateway authenticate guests, but the
Social local rail calls `_selectChoice('create')` directly. A guest can therefore
open the full Create workbench without the sign-in journey and only discovers
the boundary later through a failed provider publish.

## Bounded correction

Gate the local Create rail before changing tabs. A guest starts real sign-in
with exact return `/app/social?sub=create`; the workbench remains unmounted and
no content write occurs. Signed-in navigation remains unchanged.

No backend, provider, device, build, Play, Hosting, or communication action is
part of this correction.

## Verification

The Create, authentication and gateway focused corpus passed 22 tests with zero
failures. The exact log is
`artifacts/quality/uaw-personal-mvp-social-play-internal-live-read-recovery-c30t-continuous-audit-20260813-03/guest-create-rail-signin-focused-tests.log`
with SHA-256
`1B4DE63E29654C915F04B37917CDDCF1C4EB8D27AF7DAE39971E4141A190EEBD`.

A release AAB remains separately founder-gated.
