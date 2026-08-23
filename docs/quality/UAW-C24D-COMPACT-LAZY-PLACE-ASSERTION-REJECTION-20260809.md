# C24D compact lazy-place assertion rejection — 2026-08-09

The first focused adaptive test expected `ride-place-home` to be constructed
before scrolling at 320x568 and 1.4 text scale. The production owner is a
vertical lazy `ListView`, so this rejected correct compact behavior rather than
proving reachability.

The permanent correction keeps the primary pickup and destination-search
assertions at first paint, scrolls the exact list to the saved-place key, and
then verifies the card, connected launcher and zero layout exceptions.

No production behavior was weakened or bypassed.
