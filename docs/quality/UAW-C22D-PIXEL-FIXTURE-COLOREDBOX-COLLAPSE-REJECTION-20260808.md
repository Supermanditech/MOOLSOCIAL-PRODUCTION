# C22D pixel-fixture ColoredBox collapse — 2026-08-08

The diagnostic established a 360×640 capture, local rail `y=540..592`, and global rail `y=592..640`. The childless `ColoredBox` supplied as `Scaffold.body` had no tight vertical extent, so those coordinates sampled the default Scaffold canvas. REG-20260808-534 requires an explicitly expanding destination fixture before interpreting raw pixels.
