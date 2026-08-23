# C32O Buy router test obsolete no-local-rail and chooser-action keys

Date: 15 August 2026
Regression: `REG-20260815-2265-C32O-BUY-ROUTER-TEST-OBSOLETE-NO-LOCAL-RAIL-AND-CHOOSER-ACTION-KEYS`

After C32O replaced the obsolete launcher key, its dual-host source gates passed. The focused Buy router file then passed six cases and failed three. The remaining failures show that the predecessor test expects `buy-local-destination-tabs` to be absent and attempts `mool-navigator-buy-orders` / `mool-navigator-buy-shop` inside the family chooser.

The current accepted C26D topology separates the compact family chooser from the persistent Buy local rail. No runtime or baseline file changed. A separate exact test-topology successor is required before retry.
