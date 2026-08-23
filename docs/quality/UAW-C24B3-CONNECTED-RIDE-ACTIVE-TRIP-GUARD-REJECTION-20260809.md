# C24B3 connected Ride active-trip guard rejection — 2026-08-09

The connected chooser routed Bike/Auto/Cab through the generic global switch,
bypassing Ride's existing `openRideType` lifecycle guard. During an active Auto
trip, selecting Cab must not abandon or reset the trip.

REG663 delegates same-family connected Ride actions to the domain guard. The
trip and selected type remain exact, the live owner stays mounted, and the user
receives a visible blocking notice.
