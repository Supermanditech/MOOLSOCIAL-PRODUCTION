# C33A steady-state indicator measured before settle

The first analyzed and dual-host-gated C33A Flutter run produced 2 passes and
4 failures. Every family failure occurred at the unselected indicator-width
assertion: expected settled width 0, observed 14.

The matrix remounts the same action keys with different selected indices.
`_mountFamily` pumps only one frame, so the previous selected indicator remains
at its 14-pixel starting width while animating to zero. The separate
reduced-motion and one-tap case passed.

REG-2303 must be registered before retry. The steady-state matrix harness must
settle current state before measuring geometry; reduced-motion duration and
interaction behavior remain independently asserted. No production animation
or runtime source change is authorized.
