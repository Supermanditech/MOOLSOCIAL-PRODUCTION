# C15 transparent gradient wave family connection preselection assessment

Date: 2026-08-08

Ticket:
`UAW-PERSONAL-MVP-TRANSPARENT-GRADIENT-WAVE-FAMILY-CONNECTION-FIX1-C15`

Classification: `mvp_required`

## Customer outcome and necessity

A Personal customer sees the selected local sub-action as a direct part of the
selected main-action family and changes it with one tap. Destination content
remains fully visible behind and beside the sub-action text. A finite gradient
wave visibly joins the selected main action to the selected local action and
moves in the same direction as the person's selection.

The founder inspected the checksum-matched r60.14 OPPO candidate and found its
44px unboxed geometry likely acceptable, but the static row still did not look
connected to its main-action family. The founder explicitly requested removal
of the remaining side-to-side surface and a transparent wave connection that
moves backward or forward between selected local actions. This is a confirmed
supported-MVP navigation comprehension defect, not speculative motion polish.

## Reuse and duplicate search

The shared `MoolDestinationNavigationV2` wrapper already composes the local
controls with the unchanged global rail. Existing Social, Buy, Eat, Ride, Book
and Work owners already hold every label, selected value, route, callback,
semantic and tap target. No new screen, route, controller, service, backend or
persistent state owner is needed.

Disposition:

- `reuse`: all six local action inventories, routes, callbacks, selection
  owners and the approved global rail;
- `configuration`: the selected local index/count and the existing destination
  accent supplied to the shared wrapper;
- `new_necessary_work`: one shared noninteractive finite gradient-wave painter
  inside the existing wrapper; and
- `test_only_acceptance`: fully transparent surface, exact wave endpoints and
  direction, 44px tap geometry, reduced motion, content visibility and existing
  navigation continuity.

Duplicate search found no need for another destination wrapper or per-feature
motion owner. Implementing the connection once in the shared wrapper prevents
six visual variants and stays inside the 60–75-day robust-MVP lock with an
estimated one-day impact.

## Smallest complete scope and exclusions

Remove the wrapper's side-to-side tint so only the existing sub-action text,
compact icons, selected identity and an `IgnorePointer`/semantics-excluded
gradient connection overlay remain. Animate selection changes for 180–220ms;
reduced-motion users receive the same settled connection immediately. Keep the
44px one-tap targets and global rail exactly unchanged.

There is no new panel, card, pill, menu, modal, extra tap, screen, route,
backend, provider, business state, credential, live message/call, payment,
fund movement, Production write, protected-reference update, commit, push,
deployment or promotion.
