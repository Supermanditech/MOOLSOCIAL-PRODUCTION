# Post-C33C C16F exact-fit Bus action off-screen

C16F preserves one pass and one failure. The reduced-motion Book chooser
passes. The first case opens Ride through the Mool switcher, then taps
`ride-local-bus`; Flutter reports that the control's center is off-screen, the
tap misses, and `bus-booking-home` is absent.

At 320dp the shared destination row leaves the local rail exactly 182 logical
pixels. Four 44-pixel actions plus three 2-pixel gaps require exactly 182.
C33C subtracts 16 additional logical pixels for token insets when deciding
whether overflow is required even though the rendered cluster has no matching
leading/trailing padding. It therefore hides Bus unnecessarily.

REG-2312 blocks an unchanged retry. A successor must use the physical rail
width for the real 182-pixel fit decision, preserve 44-pixel targets and only
scroll below that minimum. No provider, route, screen, service or backend
scope is implicated.
