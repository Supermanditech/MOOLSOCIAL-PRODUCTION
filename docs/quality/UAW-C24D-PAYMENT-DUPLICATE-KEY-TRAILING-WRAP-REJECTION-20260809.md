# C24D payment duplicate-key/trailing-wrap rejection — 2026-08-09

The first Ride composition reused `ride-payment-card` for both the summary and
the Card choice and put three payment chips into a narrow service-card trailing
slot. That would duplicate test/semantics ownership and risk compact-width
overflow.

REG669 keeps payment choices in a full-width wrapping white surface with a
unique summary key and reserves trailing slots for bounded content.
