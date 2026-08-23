# UAW C33G FIX3 pending-intent restart assumption

The first focused restart test reconstructed a guest session after `beginSignIn` and one microtask, but the session resumed ready. This result is not accepted as either a product defect or a passing persistence claim until the exact JourneySession persistence owner and stored snapshot are inspected.

The test must use a deterministic persistence completion contract and prove the snapshot projection before reconstruction.
