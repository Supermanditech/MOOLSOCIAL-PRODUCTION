# C24D Ride destination Home preselection assessment — 2026-08-09

## Customer outcome and MVP classification

The personal customer can see the current pickup, enter or select a destination
and compare truthful Bike, Auto and Cab fare, arrival, capacity and payment
information before confirming. This is `mvp_required`: Ride is an approved
launch family and all three active vehicle actions require a usable booking
decision surface.

## Smallest complete implementation

- Reuse `RideBookingScreen`, `RideSession`, `RidePackage`, the existing
  `/app/ride/book?type=` route and C24B shared service-home primitives.
- Recompose the existing booking entry with current pickup and Where to first,
  direct recent/saved places, compact vehicle choices and truthful comparison.
- Preserve existing booking, schedule, active-trip, payment, safety, support,
  Back, Chat and connected-navigation owners.
- Keep Bike, Auto and Cab meanings and active-trip protection unchanged.

## Reuse and duplicate search

The production inventory contains one Ride booking screen, one session, one
package catalogue and one parameterized booking route for all three vehicle
types. C24B already owns the required responsive search, place, choice,
metadata, card and primary-button primitives. No screen, route, backend,
gateway, persistent state or subaction is needed; the disposition is `reuse`
plus presentation `configuration`.

## Explicit exclusions

- no map simulation, promo clutter, copied reference assets/trade dress or
  fabricated captain, fare, payment or availability state;
- no new Ride action, route, backend or state owner;
- no other family business-content change;
- no backend/provider/external-service write, APK build/install, commit, push,
  deploy, promotion or Production action.

## Dependencies, robustness and tests

C24A, C24B, C24B3 and C24C are complete; the reference contract, existing Ride
session/routes and protected OPPO r60.22 identity remain authoritative. Focused
tests will prove 320/390/430 widths, 1.4 text scale, minimum 44px targets,
current pickup, destination search, recent/saved places, truthful vehicle
metadata, direct booking selection, active-trip guard, Back/Chat/connected
continuity and immediate reduced motion. The affected Ride vertical slice,
analyzer, regression memory, MVP scope, delivery discipline and protected UI
locks must pass. The estimated impact is one day within the 60–75-day lock.
