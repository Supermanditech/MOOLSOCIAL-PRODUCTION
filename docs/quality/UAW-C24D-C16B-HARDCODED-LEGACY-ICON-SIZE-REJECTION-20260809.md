# C24D C16B hard-coded legacy icon-size rejection

- Observed: 2026-08-09 in the focused protected Social test cycle.
- Rejected assertion: the historical harness expected a 20px Feed icon and 20px optical box; current shared tokens specify 18px.
- Correction: use `MoolLocalNavigationTokens.iconSize` for both assertions. This does not restore the rejected local rail to production.
