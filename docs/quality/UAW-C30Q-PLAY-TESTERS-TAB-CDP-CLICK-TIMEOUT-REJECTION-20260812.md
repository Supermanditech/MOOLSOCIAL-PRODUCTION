# C30Q Play Testers tab CDP click timeout rejection

Date: 2026-08-12

## Mistake

After the C30Q Internal Testing release became active, the first attempt to open its Testers tab used the visible semantic tab control. Chrome found the exact visible tab but its page-control command timed out before the click completed.

## Impact

- The published Internal Testing release remained active and unchanged.
- No tester list, release, repository machine state, device state, credential, or secret changed.

## Permanent prevention

Do not repeat the stalled click. Reuse the authoritative current Internal Testing track URL, navigate once to its `tab=testers` form, and verify the visible tester list and opt-in link from that exact page.
