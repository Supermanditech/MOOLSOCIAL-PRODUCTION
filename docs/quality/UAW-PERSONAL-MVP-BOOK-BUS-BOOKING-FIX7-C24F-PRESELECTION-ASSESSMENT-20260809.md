# C24F Book / Bus preselection assessment — 2026-08-09

## Selection

`UAW-PERSONAL-MVP-BOOK-BUS-BOOKING-FIX7-C24F` is selected only after C24E host
qualification. It is MVP-required by the founder's explicit Bus amendment.

## Reuse and duplicate result

The bounded native-Flutter source/test search found no existing Bus product,
route, model, session, gateway or test owner. The minimum non-duplicate change
is one `BusBookingScreen`, one `/app/book/bus` route and one Book/Bus connected
action. Existing `BookSession`, `BookGateway`, `BookPageScaffold`, shared
service-home primitives, journey router and connected navigator remain the
owners; no second feature shell, gateway, backend or persistence layer is
allowed.

## Minimum complete scope

- From, To and Date controls with a one-tap swap and Today/Tomorrow shortcuts.
- Deterministic review-gateway search results showing operator, departure,
  arrival, duration, available seats, rating and fare.
- One 44px-or-larger selection/review action with explicit non-confirmation
  copy; no fabricated payment, live inventory or issued-ticket claim.
- Doctor, Salon and Bus appear once in Book; Medicine remains Buy-only.
- 320/390/430 widths, 140% text, semantics, finite/reduced motion, Back, Chat
  and connected MoolSocial continuity.

## Authority boundary

Runtime/test/gate writes for C24F are open. Backend, external service, build,
install, commit, push, deploy, promotion, Production, credentials, messages,
calls, funds, uninstall, data clear and downgrade remain closed.
