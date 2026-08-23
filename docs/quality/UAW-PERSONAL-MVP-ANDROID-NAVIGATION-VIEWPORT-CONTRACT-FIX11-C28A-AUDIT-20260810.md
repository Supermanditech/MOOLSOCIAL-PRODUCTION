# C28A Android navigation viewport audit

State: root contract selected; runtime mutation not authorized in C28A.

## Reproduced predecessor evidence

- Installed OPPO candidate remains `1.0.0-r60.26` / `2026081026`.
- OPPO CPH2375 is Android 13 at 320 dpi with a 720×1612 physical display and
  three-button system navigation.
- The retained C27F screenshot paints the approved rail from approximately
  y=1404 through y=1524, directly above the system navigation controls.
- Android UIAutomator exports its root only through y=1442 and clips every
  rail cell to y=1404..1442: 38 physical or 19 logical pixels high.
- The failure reproduces on a retained Ride state as well as retained Social,
  proving it is not a family screen, label, icon, colour or local rail defect.

## Shared-owner inventory

The six families use one visual/interaction chain:

1. `MoolDestinationNavigationV2` owns the shared destination canvas, fixed
   58px rail, SafeArea and Mool/family/local composition.
2. `MoolGlobalNavigationV2` and `_MoolHomeLauncher` own the embedded vertical
   Mool switcher and its compact rail cell.
3. `MoolLocalNavigationRail` and `_MoolLocalNavigationCell` own all 18 local
   actions through shared typography, icon, spacing, selected-state and tap
   tokens.
4. Social, Buy, Eat, Ride, Book and Work project these owners through their
   existing Scaffolds; no feature-local replacement is necessary.
5. `MainActivity` currently owns no explicit Android system-bar/window-fit
   compatibility behavior.

## Root cause and required contract

The Flutter semantic cells already own 54×58 or wider geometry. On the OPPO,
the edge-to-edge Flutter surface is taller than the Android exported
accessibility viewport used by UIAutomator, so Android clips the shared cell at
the viewport boundary. Adding another inner `Semantics` wrapper cannot repair
an outer window clip.

The successor must make the Android Flutter view and its system-bar insets use
one truthful coordinate space on supported pre-Android-15 devices while
retaining mandatory edge-to-edge behavior where the OS enforces it. The
approved 58px visual rail, content hierarchy and family catalogue stay
unchanged. A density-normalized device gate must reject any Mool, family or
local node below 44×44 logical before the screenshot matrix begins.

## Explicit exclusions

No new route, screen, feature state, customer copy, theme, animation, backend,
provider action or second rail owner. No r60.26 mutation, build or install in
C28A.
