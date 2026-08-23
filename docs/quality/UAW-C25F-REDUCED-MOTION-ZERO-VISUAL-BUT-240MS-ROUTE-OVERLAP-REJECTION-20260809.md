# C25F reduced-motion route-overlap rejection

Date: 2026-08-09

## Runtime finding

The migrated C10E suite passed seven of eight cases. In reduced-motion mode,
the Work owner appeared immediately and no Fade/Slide transition rendered, but
two `mool-compact-launcher` widgets remained in the tree. The destination page
always used 240ms transition and reverse-transition durations, so Navigator
kept the old route alive even when its transitions builder returned the child.

## Required correction

When platform accessibility reports `disableAnimations` or
`accessibleNavigation`, both destination route durations must be zero. Standard
mode must retain `MoolMotion.standard` (240ms). The focused test must then prove
one Work owner, one compact launcher, no visual transition and no exception
after the immediate switch.

No build or install authority is opened.
