# C10E Ride local type switch duplicate route notification

Date: 2026-08-07

Ticket: `UAW-PERSONAL-MVP-GLOBAL-NAVIGATION-MOTION-CONTAINMENT-OPPO-FIX1-C10E`

Switching Bike to Auto from the Ride booking root selected the new type and
then pushed another `/app/ride/book` page. The successor booking widget called
`prepareBooking` in `initState` while the outgoing booking page still listened
to the same `RideSession`, producing `markNeedsBuild during build`.

A local Ride type is an in-place choice on the existing booking owner, not a
new page. The booking root now identifies its active local action explicitly;
type switches update the existing session and do not add route history. Other
Ride depths still navigate to the booking owner when no active trip blocks the
switch. The FIX2 exact Chat/Mool round trip remains the behavioral gate.
