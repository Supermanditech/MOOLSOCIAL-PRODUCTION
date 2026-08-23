# C25F Fix1 wording/wiring predecessor contract rejection

- Date: 2026-08-09
- Status: registered before test migration

The retained Fix1 suite produced eleven failures because it still locked Buy/Eat/Ride/Book labels, two-tap Home subaction keys, and the removed destination launcher. C25’s founder-approved contract renames those customer domains to Shop/Food/Travel/Care, makes Home main-only with one-tap default routes, and uses the compact destination launcher.

The migration updates only the superseded naming and shell tap sequence. It retains all exact production-owner route assertions, destination Back preservation and Home Chat exact-return behavior.
