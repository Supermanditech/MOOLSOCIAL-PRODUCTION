# C13 primary root chooser bypasses the family rail

Date: 2026-08-07

Regression:
`REG-20260807-270-C13-PRIMARY-ROOT-CHOOSER-BYPASSES-FAMILY-RAIL`

## Escaped defect

C12 host qualification mounted destination-owned sub-action routes and proved
their family rails, but did not tap every global main action through the
production router and inspect the first landed frame. The installed r60.12 APK
therefore passed host tests while Eat, Ride, Book and Work still opened old
choice roots without a family rail and required an extra tap.

## Root cause

The tests proved deep-route presentation, not the route value owned by each
`PersonalMoolActionSpec`. The dynamic `/app/:section` production path could
still render `MvpActionChoiceRootV2`, and no static gate rejected those retired
root routes.

## Permanent prevention

1. The main-action contract names the existing default sub-action route for
   every supported destination.
2. Production stale-root links resolve to the same defaults before a chooser
   can render.
3. A production-router widget test taps each global action once and requires
   the first landed frame to contain the correct family rail and selected
   default action while chooser copy is absent.
4. The static placement gate rejects affected global action routes that point
   at `/app/eat`, `/app/ride`, `/app/book` or `/app/work`.
5. OPPO qualification captures the untouched first frame for every main action
   before Back, Mool, Chat or local-action continuity can pass.

Retained failure evidence:
`docs/quality/UAW-C12-R60-12-LEGACY-ROOT-CHOOSER-OPPO-REJECTION-20260807.md`.
