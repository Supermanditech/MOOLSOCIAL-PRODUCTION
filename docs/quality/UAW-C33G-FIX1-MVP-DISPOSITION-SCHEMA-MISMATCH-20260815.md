# UAW C33G FIX1 MVP disposition schema mismatch

The first C33G FIX1 MVP scope-gate attempt stopped before source mutation because the new assessment used `thin_adapter`, while the machine policy's exact allowed value is `thin_policy_adapter`.

The retry changes only that classification label in the ticket, retained assessment and live scope state, then refreshes the ticket manifest hash. Scope, owners, authorities and exclusions remain unchanged.
