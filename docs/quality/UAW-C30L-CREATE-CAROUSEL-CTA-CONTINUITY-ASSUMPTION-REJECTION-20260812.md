# C30L Create Carousel CTA-continuity assumption rejection

- ID: `REG-20260812-1430-C30L-CREATE-CAROUSEL-CTA-CONTINUITY-ASSUMPTION-REJECTION`
- Date: 2026-08-12
- Scope: bounded OPPO Create navigation replay
- Result: final chained lookup rejected; Image Poll, Quiz and Carousel captures remain valid

Carousel uses a format-specific composer state and does not expose the shared `YouTube Short` action in its captured hierarchy. The replay stops at that state, preserves the completed evidence, and will inspect Carousel before returning through an observed semantic control. No post was submitted and no cloud write occurred.
