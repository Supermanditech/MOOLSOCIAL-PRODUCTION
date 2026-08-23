# C14 Ride in-place type switch Back-history recurrence

Date: 2026-08-08

Regression:
`REG-20260808-287-C14-RIDE-IN-PLACE-TYPE-SWITCH-BACK-HISTORY-RECURRENCE`

## Failure

The first R07 migration edit correctly removed the retired Ride chooser, but
again expected Auto and Cab to create Back history and restore Bike. Focused
execution proved the route owner remained correct while the selected session
type intentionally remained Auto or Cab.

## Root cause and prevention

The generic non-default-subaction Back rule was applied without reconciling
the registered Ride-specific contract. Bike, Auto and Cab share the existing
booking owner and change `RideSession.selectedType` in place. R07 now proves
the selected type directly, visits Mool explicitly, and uses system Back to
verify restoration of the exact Ride owner and type without duplicate route
history.
