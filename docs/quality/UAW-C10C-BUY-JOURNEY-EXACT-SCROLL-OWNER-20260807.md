# UAW C10C Buy journey exact scroll owner regression

- Registry: `REG-20260807-199-BUY-JOURNEY-TESTS-SCROLLED-FIRST-GLOBAL-SCROLLABLE`
- State: resolved; exact-owner and vertical-axis test gate active
- Trigger: the combined C10C qualification batch failed six journeys with `Bad state: No element` after the persistent Buy-local destination rail became horizontally scrollable.
- Root cause: the tests used `find.byType(Scrollable).first`, whose identity changed when the local navigation rail was added.
- Durable rule: scroll through the `Scrollable` descendant of the active keyed page (`buy-product-*`, `buy-orders`, or `buy-tracking-*`), never through global widget-tree ordering.
- Proof: focused journey passed, full Buy screen suite passed 69/69, combined C10C suite passed 82/82, and broader affected routes passed 80/80.
