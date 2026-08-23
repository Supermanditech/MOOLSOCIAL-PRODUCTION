# C16D combined patch empty-hunk rejection

The first combined C16D correction patch contained an empty update hunk marker
after the test Back replacement. `apply_patch` rejected the entire mutation
atomically; source, test, gate, registry and evidence files remained unchanged.

The retry is intentionally split: permanent registry/evidence is applied and
validated first, then the smaller source/test/static-gate correction is applied
with bounded contexts and no empty hunk marker.
