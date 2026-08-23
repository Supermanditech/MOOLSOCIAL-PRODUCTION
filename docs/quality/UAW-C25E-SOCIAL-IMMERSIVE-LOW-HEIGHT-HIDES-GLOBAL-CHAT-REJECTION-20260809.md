# C25E Social immersive low-height global Chat rejection

- Date: 2026-08-09
- Scope: `UAW-PERSONAL-MVP-SIX-DOMAIN-ROUTE-PROJECTION-CONTINUITY-FIX8-C25E`
- Status: registered before correction

## Rejection

The protected Social header returned an empty widget whenever immersive content was shown at a height of 650 logical pixels or less. After assigning global Chat to the stable header action zone, that predecessor rule would make Chat undiscoverable and unreachable on compact-height Social surfaces.

## Prevention

Keep the compact Social action row mounted at supported heights. Immersive presentation may reduce header padding, but it must not remove the one-tap global Chat control or the other established header utilities.

## Gate

C25F must exercise Social at the compact adaptive viewport and assert a visible, enabled, at-least-44px Chat target.
