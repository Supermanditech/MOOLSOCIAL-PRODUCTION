# C22C decoration-border hit-surface rejection

The first rendered main capsule's outer request was 72 × 48, but its border lived in `AnimatedContainer.decoration`; decoration padding reduced the keyed `InkWell` to 70 × 46. C22C moves the border to `foregroundDecoration`, matching the local capsule and preserving the exact 72 × 48 tappable surface.
