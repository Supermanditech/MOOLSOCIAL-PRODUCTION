# C10E reduced-motion route scheduling assertion

Date: 2026-08-07

Ticket: `UAW-PERSONAL-MVP-GLOBAL-NAVIGATION-MOTION-CONTAINMENT-OPPO-FIX1-C10E`

The first reduced-motion test expected an imperatively pushed GoRouter page to
be present after the same pump that dispatched the tap. The transition builder
correctly removed Fade and Slide under reduced motion, but normal route update
scheduling still required the next frame before the destination owner was
mounted.

The prevention test now separates the invariants: it proves the visual motion
wrapper is absent, advances only the minimal route-scheduling frame, proves the
destination, and then settles. Reduced motion does not redefine asynchronous
router dispatch as a synchronous widget mutation.
