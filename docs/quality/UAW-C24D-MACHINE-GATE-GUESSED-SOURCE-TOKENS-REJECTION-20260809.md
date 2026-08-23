# C24D machine-gate guessed source-token rejection — 2026-08-09

The first C24D gate used conceptual labels and guessed identifiers rather than
the exact current source. It looked for `Ride type`, `Choose your ride`,
`package.availableCaptains`, `void updateRoute(` and a shared-primitives Inter
token. The real owners use `Choose a ride`, `nearbyCaptains`, a boolean
`updateRoute`, and keep the explicit CTA font in RideBookingScreen.

The corrected gate now binds each invariant to its formatter-stable owner and
retains the same acceptance outcome without forcing invented implementation
details.
