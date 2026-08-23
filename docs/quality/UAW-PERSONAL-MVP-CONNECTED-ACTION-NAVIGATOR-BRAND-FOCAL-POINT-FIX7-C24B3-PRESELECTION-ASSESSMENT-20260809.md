# C24B3 connected action navigator preselection assessment — 2026-08-09

## Customer outcome

From Social, Buy, Eat, Ride, Book or Work, the single persistent `MoolSocial` launcher opens the same six-family/direct-action chooser above the current destination and switches directly to the chosen outcome without an intermediate Home route.

## Reuse and duplicate search

The bounded runtime search identified one global launcher owner (`MoolGlobalNavigationV2`), one six-destination shell owner (`MoolDestinationNavigationV2`), one authoritative catalogue (`moolActionFamilies`), and existing route callbacks in all six destination shells. No connected chooser currently exists; the launcher still calls an `/app/mool` callback. A new shared `MoolConnectedActionNavigator` plus reusable chooser presentation is therefore the minimum necessary owner. It reuses the catalogue and existing callbacks and adds no screen, route, backend owner, state owner or subaction.

## Robustness coverage

- launcher text, semantics and tap area at 320, 390 and 430 widths;
- six families and selected family's two-to-four direct actions from every destination;
- destination remains mounted below the modal chooser;
- direct selection calls the existing route callback and never the old Home callback;
- barrier and System Back dismiss to unchanged destination;
- immediate reduced-motion transition and finite standard transition;
- removal only of redundant destination brand chrome, including Buy's empty brand-reservation tile;
- Social and Buy business content, routes and state remain protected.

## Authorization boundary

Runtime and focused gate changes are selected. Build, install, device mutation, backend and external actions remain closed. C24B2 is complete and installed r60.22 remains preserved.
