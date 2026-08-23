# C23F motion and accessibility completion

- Mool Home arrival is finite and capped at 220 ms.
- The only destination launcher has 100 ms pressed-state feedback.
- Reduced motion settles Home and launcher feedback immediately.
- Chat is reachable from the Home header through a 44 px native control; it is
  not restored to a persistent bottom rail.
- Large text uses the adaptive stacked family layout without horizontal action
  scrolling; Back and Chat callbacks remain continuous.
- Focused analysis passed and cumulative C23B through C23F passed: 12 tests.
- Build/install stayed closed and r60.21 remained installed and unchanged.
