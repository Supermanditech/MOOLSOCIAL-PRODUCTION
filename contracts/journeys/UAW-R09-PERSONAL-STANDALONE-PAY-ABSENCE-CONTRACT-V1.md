# UAW-R09 Personal standalone Pay absence contract V1

1. Personal Mool exposes Social, Buy, Eat, Ride, Book and Work; Chat remains
   global.
2. No Pay, Recharge, Bills, Scan & Pay or generic Receipts action is visible
   from Mool or an MVP vertical action root.
3. An authorized transaction keeps its payment and receipt action inside the
   exact owning order, booking, trip or Work record.
4. Removing launcher exposure must not delete or re-home transaction payment
   state, receipts, recovery or idempotency owners.
5. Historical standalone Pay routes remain preserved until UAW-R12 applies the
   central truthful-unavailable/deep-link containment contract.

This ticket neither initiates a payment nor changes price, money, refund,
payout, provider, backend or receipt truth.
