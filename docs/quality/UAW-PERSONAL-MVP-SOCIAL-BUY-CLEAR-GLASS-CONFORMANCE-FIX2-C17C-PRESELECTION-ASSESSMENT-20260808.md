# C17C Social and Buy clear-glass conformance preselection

Date: 2026-08-08
Ticket: `UAW-PERSONAL-MVP-SOCIAL-BUY-CLEAR-GLASS-CONFORMANCE-FIX2-C17C`

## MVP classification and customer outcome

This is MVP-required. Social and Buy are the two four-action families and Buy
is the founder's explicit wrong-colour/background-blocking rejection fixture.
Both must prove professional individual controls on their actual family
backgrounds before the remaining family counts can be accepted.

## Reuse and duplicate search

The live native owners are:

- `Screen04ContextTabs` -> existing `MoolLocalNavigationRail`, with Shorts,
  Videos, Feed and Create and the media surface tone;
- `_buildBuyLocalNavigation` -> the same rail, with Shop, Wholesale, Medicine
  and Orders and the default light surface tone;
- `MoolDestinationNavigationV2` -> the existing transparent shell and thin
  family connection owner.

The source and test inventory found no second family renderer, no new action,
no new route and no backend/state owner requirement. C17C reuses the C17B
owner and adds family-specific qualification only.

## Necessary correction found by the gate

`Screen04ContextTabs` still has a historical hard-coded 44px wrapper around
the new 52px rail. That can clip a 48px glass target and must be replaced by
`MoolLocalNavigationTokens.railHeight`. Buy already receives the authoritative
52px height from `MoolDestinationNavigationV2`.

## Minimum complete scope

1. Correct only Social's stale wrapper height and preserve its media tone,
   provider attribution semantics/assets, labels, callbacks and selected inert
   state.
2. Prove Buy uses the light tone and four individual controls with its deep
   accessible accent, no trapezoid/broad band and unchanged Shop/Wholesale/
   Medicine/Orders wiring.
3. Add one focused Social/Buy conformance suite and a static C17C gate at 320px
   and large text.
4. Preserve the existing shell, content, routes, Back/Mool/Chat and all keys.

## Explicit exclusions

No new subaction, screen, route, menu, modal, palette, filler, state owner,
backend owner, provider call, content rewrite, global rail change, build,
install, credential access, message, payment, commit, push, deploy or
promotion is authorized.

Estimated delivery-lock impact: 0.5 day, within the founder-locked 60–75 day
window. C17D cannot begin until this focused ticket passes.
