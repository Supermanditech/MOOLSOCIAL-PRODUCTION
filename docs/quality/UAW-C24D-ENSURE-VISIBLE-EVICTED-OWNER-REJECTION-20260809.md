# C24D ensureVisible evicted-owner rejection — 2026-08-09

The first correction for backward destination verification called
`ensureVisible` without proving the keyed search surface still existed. The
lazy ListView had evicted that earlier child after the saved-place scroll and
session rebuild, so the helper threw `Bad state: No element`.

The permanent gate reverse-drags the persistent `ride-booking-screen` within a
fixed attempt limit until the destination surface is constructed, requires one
matching owner, and only then calls `ensureVisible` and reads the exact selected
destination semantics.
