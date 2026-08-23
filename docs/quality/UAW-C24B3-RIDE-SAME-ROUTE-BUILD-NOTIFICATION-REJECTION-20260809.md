# C24B3 Ride same-route build notification rejection — 2026-08-09

Connected Bike-to-Auto/Cab switching changes the query on the native
`/app/ride/book` owner. The replacement screen synchronously called
`prepareBooking` in `initState`; that method notified the shared session twice
while the outgoing `AnimatedBuilder` was still mounted, causing a build-phase
`markNeedsBuild` assertion.

REG657 requires silent first-frame session preparation, one notification for
normal public mutations, and a real connected Bike-to-Auto-to-Cab route test.
