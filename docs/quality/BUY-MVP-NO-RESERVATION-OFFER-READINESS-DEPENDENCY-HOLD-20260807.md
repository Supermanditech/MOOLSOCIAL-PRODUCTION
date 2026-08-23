# Buy MVP no-reservation offer readiness dependency hold

Date: 7 August 2026
Ticket: `BUY-MVP-NO-RESERVATION-OFFER-READINESS`
Disposition: `DEPENDENCY_HELD_BEFORE_EXECUTION`

The ticket requires SUP-003 plus named inventory and fulfilment owners. The
local SUP-003 catalogue/offer contract is technically qualified at
`backend/functions/src/commerce/catalogue_contract.ts` with current SHA-256
`471E0D05EEFF969E4EE62D1D2A6C94259145BCA7D3E133B7800739963FF5DCCE`.
It provides stable product, verified pack and participant-offer identity only.

The production authority still marks SUP-004 inventory/serviceability truth as
`BLOCKED` pending inventory/logistics owners, and SUP-005 depends on SUP-004.
Current commerce source search found no authoritative fresh inventory,
destination serviceability or fulfilment-quote owner; the only match was a
comment explicitly listing those facts as external inputs. No machine state or
owner evidence names an activated `inventory_owner` or `fulfilment_owner` for
this ticket.

Implementing now would either fabricate stock/serviceability truth, invent an
unowned fact interface that appears authoritative, or weaken the exact
dependency gate. Founder portfolio authorization explicitly retains named
dependency gates. Therefore no source, test, store, endpoint, UI, build, OPPO or
live mutation is authorized for Ticket 6 yet.

Unblock requires durable production-repository evidence naming the inventory
and fulfilment owners and qualifying the exact fresh, expiring, explicit
unknown/stale/partial/unavailable fact contract. Reservation remains excluded;
readiness must not create a stock hold or a live stock claim.
