# C11 C10E first gate correction overbroad Shared owner

- Regression: `REG-20260807-252-C11-C10E-FIRST-GATE-CORRECTION-OVERBROAD-SHARED-OWNER`
- Ticket: `UAW-PERSONAL-MVP-CONTEXTUAL-SUBACTION-THUMB-SHELF-FIX1-C11`
- Date: 2026-08-07 IST

## Observation

The first C10E gate correction correctly accepted the C11 shelf composition
for Eat, Ride, Book and Work, but also required it from
`shared_screens.dart`. Shared is present in the older C10E owner inventory but
is not one of the six founder-approved C11 destinations.

## Permanent correction

The checker now distinguishes the exact non-C11 Shared owner. Eat, Ride, Book
and Work must use the shared destination shelf; Shared must retain its direct
global rail; every owner must still retain its existing local rail. This keeps
C11 scoped precisely without weakening C10E's broader navigation contract.
