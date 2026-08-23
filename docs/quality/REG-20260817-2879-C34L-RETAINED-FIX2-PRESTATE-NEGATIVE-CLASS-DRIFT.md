# REG2879 — C34L retained FIX2 pre-state negative class drift

- Status: registered first PowerShell 7 retained/recovery fixture failure; no retry.
- Failure: the existing pre-state-hash fixture was correctly rejected by the newly earlier exact newest-proof binding invariant, but its oracle still expected the old standalone preimage message.
- Root cause: validation order and specificity were strengthened without updating this one negative's intended exact rejection class.
- Prevention: align only this fixture to the new proof-binding class, retain distinct proof-history and standalone preimage negatives, then rerun the memory gate and PowerShell 7 before Windows PowerShell.
- Containment: fixture `finally` ran; no real recovery, state, release, private, device, or external action.
