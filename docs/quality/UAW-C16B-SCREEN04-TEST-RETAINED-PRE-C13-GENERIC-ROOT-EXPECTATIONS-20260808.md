# C16B Screen 04 test retained pre-C13 generic-root expectations

## Incident

The isolated Screen 04 main-action loop navigated through the current
`personalMoolRootActions`, whose authorized default routes are Eat home, Ride
booking, Book doctor and Work earn. The test nevertheless expected the retired
pre-C13 generic `mvp-action-root-eat/ride/book/work` owners, causing the Eat
failure at the first affected action.

## Root cause and prevention

The Screen 04 cross-navigation test was not migrated when C13 made exact
customer defaults render before the generic action-choice owner. The test now
expects `eat-home-screen`, `ride-booking-screen`, `book-doctor` and
`work-earn-screen`, matching the current route authority and C10E coverage. No
production route is changed to satisfy a stale test.
