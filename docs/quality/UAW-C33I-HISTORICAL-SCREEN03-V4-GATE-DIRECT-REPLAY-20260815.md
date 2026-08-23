# C33I historical Screen 03 v4 gate direct replay regression

- Regression: `REG-20260815-2476-C33I-HISTORICAL-SCREEN03-V4-GATE-DIRECT-REPLAY`
- Failure: C33I directly invoked the C30X FIX1 historical v4 acceptance gate, which rejected the unrelated current ticket scope exactly as designed.
- Impact: the current C33I scope, delivery-discipline and approved UI locks had already passed; no reference, runtime, provider, email, Hosting or device state changed.
- Prevention: under later tickets, use the global approved UI lock and an exact registered successor containment owner if one exists. Never directly replay the historical C30X FIX1 gate under an unrelated active ticket.
