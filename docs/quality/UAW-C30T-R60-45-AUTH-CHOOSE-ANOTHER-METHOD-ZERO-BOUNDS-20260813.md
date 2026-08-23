# UAW C30T r60.45 auth Choose another method zero bounds — 13 August 2026

## Release result

The Play-installed `1.0.0-r60.45 (2026081345)` sign-in failure sheet visibly renders `Choose another method`, but UIAutomator reports its clickable node at `[0,0][0,0]`. The action therefore has no usable accessibility or semantic tap geometry even though the founder could target the visible text manually.

## Exact evidence

- UI hierarchy: `artifacts/quality/uaw-personal-mvp-social-play-internal-live-read-recovery-c30t-r60-45-20260813-01/34-auth-google-retry-loop.xml`
- Screenshot: `artifacts/quality/uaw-personal-mvp-social-play-internal-live-read-recovery-c30t-r60-45-20260813-01/34-auth-google-retry-loop.png`
- Exact exported bounds: `[0,0][0,0]`

## Successor boundary

The smallest correction is one non-empty clickable secondary recovery node at least 48 logical pixels in both dimensions, with deterministic focus order after `Try again` and a proved return to the provider grid. A current-owner semantics-bounds regression is required.

Implementation is founder-authorized after full Social/global acceptance. No second AAB, upload or install is authorized.

## Pre-selection robustness and reuse assessment

- Classification: `mvp_required`; a visible but zero-bounds recovery action is
  not operable through keyboard switch or assistive-technology navigation.
- Reuse: the current Screen 03 recovery sheet and its current-owner widget test
  already own the complete action, visual order and provider-grid return.
- Minimum correction: give the existing secondary action an explicit 48x48
  minimum, preserve its one clickable semantic node and focus order after
  `Try again`, and prove both normal `Choose another method` and YouTube-specific
  `Cancel and return` behavior.
- New screens, routes, providers and backend owners: none.
- Exclusions: no provider/backend expansion, secret access, build, AAB, upload,
  install or device mutation.

The ticket is selected for source-only implementation. A future separately
authorized Play candidate is still required for OPPO UIAutomator bounds proof.

## Source implementation result — 2026-08-13

The existing recovery sheet now gives its secondary action an explicit padded
minimum height of 48 logical pixels; the sheet's stretch layout provides more
than 48 pixels of width. `Try again` and the secondary action have explicit
numeric traversal order 1 and 2. The TextButton remains the one tappable
semantic owner—no duplicate semantics node or route was added.

Current-owner tests measure both dimensions, require the exact semantic label
and tap action, prove the numeric focus order, and verify that general
`Choose another method` clears only the failed provider result and returns to
the provider grid. The already source-qualified YouTube handoff continues to
show only Google and uses `Cancel and return`; Email/Mobile OTP and unrelated
social methods remain absent from that exact purpose.

Qualification completed without a build, upload, install, provider deployment,
device write or external action:

- authentication/session/Firebase/YouTube-return partition: 32 passed;
- Screen 01–03 fitment plus C30T Feed-auth partition: 18 passed;
- analyzer: both exact runtime/test owners clean.

State is
`source_implemented_focused_tests_passed_live_Play_UIAutomator_acceptance_pending`.
A future separately authorized Play candidate must still prove non-zero OPPO
UIAutomator bounds and assistive-technology operation. No successor AAB is
authorized by this result.
