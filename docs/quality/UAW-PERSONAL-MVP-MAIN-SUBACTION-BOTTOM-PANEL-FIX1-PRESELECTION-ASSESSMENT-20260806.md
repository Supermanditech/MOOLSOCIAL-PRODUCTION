# Personal main/sub-action bottom-panel FIX1 preselection assessment

Date: 6 August 2026
Ticket: `UAW-PERSONAL-MVP-MAIN-SUBACTION-BOTTOM-PANEL-FIX1`
Classification: `mvp_required`

## Customer outcome

From Mool root, any Personal vertical chooser or any downstream Personal
product/service owner, the user can tap Mool and immediately see all six main
actions in a production bottom action panel. Android/gesture Back or visible
Close returns to the exact unchanged screen. Choosing a main action uses its
existing owner and route. The contextual sub-action rail remains visible and
selected whenever the panel is closed.

The real OPPO audit proves the root Mool tile is selected but non-interactive,
and contextual Mool leaves the current downstream state for the root rather
than exposing main actions in the panel. This is a reachable navigation gap in
the founder-authorized robust MVP.

## Reuse and smallest complete implementation

- Reuse `personalMoolRootActions`, their exact icons/labels/routes,
  `PersonalMoolRootV2`, `MvpActionChoiceRootV2`, `MoolOutcomeDock`, existing
  Eat/Ride/Book/Work docks, GoRouter, native `showModalBottomSheet`, design
  tokens and existing destination/session owners.
- Add one reusable presentation-only `PersonalMoolActionPanel` in the existing
  Personal Mool owner. It creates no named route, screen, session, store,
  service or backend owner.
- Make the root Mool tile a real button labelled `Open Mool actions`.
- Route every Personal chooser/downstream Mool action to the same panel.
- Panel items: Mool home plus Social, Buy, Eat, Ride, Book and Work. Mark the
  active main action. Do not duplicate Chat in the panel because Chat remains
  the stable dock edge action.
- Dismiss Close/system/gesture Back to the exact unchanged chooser/downstream
  state. Selecting an item closes the panel then uses the existing route.
- Use finite native bottom-sheet motion and resolve it immediately for reduced
  motion. Preserve >=44-point targets, safe areas, scrolling, scaled text and
  semantic selected/button state.
- Carry the host-qualified FIX3 Ride query-return correction into the eventual
  combined candidate without creating an intermediate APK.

## Duplicate search and necessity

Protected Social and Buy have their own approved rail/palette implementations,
but they are protected runtime owners and cannot be imported, rewritten or
made dependencies of this Personal ticket. The shared `MoolOutcomeDock` owns
the stable edge/sub-action language but has no main-action panel capability.
The Personal main-action list and routes already exist in one authority. A
single presentation-only panel over that list is the smallest non-duplicative
Personal correction and does not alter protected trees.

## Exclusions

- No new main/sub-action, named route, screen, state, session, service, store,
  backend, provider, payment or workspace owner.
- No protected Social/Buy runtime, golden, baseline, catalogue, checkout,
  provider or YouTube change.
- No active lifecycle reset, silent abandonment, fabricated service result,
  perpetual motion, screenbook/reference/manifest change or legacy deletion.
- No OPPO uninstall/data clear/downgrade, credentials, live message/call,
  funds, Production write, commit, push, deploy or promotion.
- No alteration/deletion of rejected FIX1/r60.4, rejected FIX2/r60.5 or
  host-qualified/unbuilt FIX3 evidence.

Estimated impact: **1 day**, inside the founder-locked 60-75-day window.
