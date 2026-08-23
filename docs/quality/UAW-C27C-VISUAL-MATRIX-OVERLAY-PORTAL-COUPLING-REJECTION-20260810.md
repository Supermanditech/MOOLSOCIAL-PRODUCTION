# C27C visual-matrix OverlayPortal coupling rejection

## Observation

Invoking the launcher's InkWell callback directly still did not materialize the
portal panel in the large 360x800 presentation matrix, although the independent
320x568 reduced-motion drag test continued to open and dismiss the same portal.

## Cause

The presentation matrix remained coupled to OverlayPortal lifecycle and
composited-follower behavior that it did not need to test. The public
`MoolConnectedActionNavigator` is the direct visual owner of the glass panel
and six rows.

## Permanent prevention

Visual token matrices mount the public panel owner directly at the shared width.
Dedicated C26C and C27C interaction tests mount the complete launcher/portal
path for tap, swipe, outside tap, Back and reduced motion.

## Resolution evidence

The third exact failure was recorded before refactoring the visual matrix to its
actual presentation owner.
