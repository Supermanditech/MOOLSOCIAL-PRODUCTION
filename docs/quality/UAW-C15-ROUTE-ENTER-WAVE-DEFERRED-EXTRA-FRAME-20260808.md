# C15 route-enter wave deferred an extra frame

Date: 2026-08-08

Regression ID:
`REG-20260808-296-C15-ROUTE-ENTER-WAVE-DEFERRED-EXTRA-FRAME`

The second focused run passed Social, Buy, Ride and all six reduced-motion
cases. Eat, Book and Work correctly initialized their incoming shared wave
from the outgoing local position toward the new local position, but the
controller stayed at zero through the first measured route-transition frame.
It was started by an additional post-frame callback.

Root cause: same-owner updates started the controller immediately, while a new
route-mounted wrapper deferred its start by one extra frame even though
`didChangeDependencies` had already supplied the reduced-motion decision.

Permanent prevention: an incoming route-mounted wave starts its finite
controller immediately in `didChangeDependencies` when motion is enabled.
Reduced motion still jumps directly to the new settled endpoint. Tests cover
both in-place and route-to-route local selections at an intermediate frame.
