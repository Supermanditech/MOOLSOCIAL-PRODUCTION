# C26B preselection — transparent unboxed destination rail

Classification: `mvp_required`.

Customer outcome: every personal family presents Mool, its named root and all
truthful local actions in one compact thumb-reachable bottom row without the
old capsules, glass cards, family themes, straps or horizontal scrolling.

## Reuse inventory

- `MoolDestinationNavigationV2` owns the bottom shell for all six families.
- `MoolLocalNavigationRail`, `MoolLocalNavigationAction` and
  `MoolLocalNavigationTokens` own the shared local action presentation.
- Exactly six existing call sites project Social, Shop, Food, Travel, Care and
  Work; their existing callbacks, sessions and routes remain unchanged.
- Existing global Chat header shortcuts remain one tap and are not duplicated
  into the constrained bottom row.

Duplicate search found no second personal bottom-shell owner requiring
mutation. `MoolOutcomeDock` belongs to other workspace types and is outside
this personal-family ticket. No screen, route, state or backend owner is added.

## Smallest implementation and evidence

Replace the rendered shared rail cell and destination-shell composition once,
add the named family root as a shared control, retain 44px minimum targets, and
prove six family/action counts at 320, 390 and 430 logical-pixel widths with
text scale through 1.4. No build or install is authorized in C26B.
