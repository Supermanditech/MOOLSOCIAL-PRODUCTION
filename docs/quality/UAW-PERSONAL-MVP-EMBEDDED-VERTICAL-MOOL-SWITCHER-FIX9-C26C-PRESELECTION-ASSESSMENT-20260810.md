# C26C preselection — embedded vertical Mool switcher

Classification: `mvp_required`.

Customer outcome: tapping or swiping up on Mool reveals all six main families
in a thin connected vertical glass dock that remains part of the current native
screen rather than appearing as a separate modal page.

## Reuse inventory

- `MoolGlobalNavigationV2` owns the global launcher and selection result.
- `MoolConnectedActionNavigator` and `MoolMainDomainMenu` own the current menu
  presentation.
- `moolActionFamilies` owns the six labels, icons, order and default routes.
- Flutter `OverlayPortal`, composited transforms and PopScope already exist in
  the current runtime and require no package, route or state owner.

The current `showGeneralDialog`, dim barrier, centred card, header and close
button are the presentation being replaced. Duplicate search found no second
personal global-switcher owner. No new screen, route, action or backend owner is
necessary.

## Smallest implementation and evidence

Recompose the existing launcher as the anchor for one overlay portal, render six
56px vertical rows with approved semantic accents, and support tap/swipe-up
open plus family tap/swipe-down/outside tap/Back close. Motion is finite 180ms
and immediate under reduced motion. Focused widget and machine gates precede
any family conformance ticket; no build or install is authorized in C26C.
