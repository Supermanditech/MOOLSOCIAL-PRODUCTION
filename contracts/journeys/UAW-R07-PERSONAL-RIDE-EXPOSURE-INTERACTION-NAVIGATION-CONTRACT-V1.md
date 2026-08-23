# UAW-R07 Personal Ride exposure interaction and navigation contract V1

1. Tap **Ride** on Mool to push `/app/ride`.
2. Ride shows exactly **Bike**, **Auto** and **Cab**.
3. Tap **Bike** to push `/app/ride/book?type=bike`.
4. Tap **Auto** to push `/app/ride/book?type=auto`.
5. Tap **Cab** to push `/app/ride/book?type=cab`.
6. The existing booking owner opens with the selected `RideType` and remains
   responsible for pickup, destination, estimate and downstream booking.
7. Visible/system Back restores the prior surface, falling back to
   `/app/mool?from=ride` on direct entry.
8. Mool opens `/app/mool?from=ride`; global Chat opens
   `/app/chat/inbox?return=/app/ride`.

The R06 shared native surface owns presentation, finite/reduced motion,
semantics, tap targets and responsive behavior. No old Ride prototype UI is a
final reference. This ticket neither dispatches a driver nor promises a fare,
payment or completed trip.
