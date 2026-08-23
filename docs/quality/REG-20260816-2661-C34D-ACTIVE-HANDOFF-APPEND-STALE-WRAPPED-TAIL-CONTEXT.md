# REG2661 — C34D active-handoff append stale wrapped-tail context

Before the C34D source seal, an active-handoff append was rejected atomically because its anchor used remembered wrapped lines rather than the exact current file tail. No handoff bytes changed and no gate result is counted. The correction requires immediate exact-tail readback followed by one anchored append and verification before any draft manifest is generated.
