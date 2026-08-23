# C25 motion-range contract rejection

Date: 2026-08-09

The C25 projection specified 180-220ms finite motion, while the retained
production `MoolMotion.standard` and predecessor C10E contract use 240ms within
the established approved 180-320ms interval. The C25F gate reported motion as
qualified without cross-checking the config bounds.

The projection maximum must be corrected to 320ms and the machine gate must
parse the runtime standard and reject any value outside its declared range.
Reduced motion remains immediate with zero route duration.
