# C26C swipe-up velocity-only gesture rejection

## Observation

A 90px deliberate upward drag did not open the embedded Mool switcher under the initial velocity-only implementation.

## Cause

Gesture completion depended on terminal velocity even when directional travel clearly expressed intent.

## Permanent prevention

- Track cumulative vertical travel for launcher and dock gestures.
- Open or close after 24px directional travel or an 80px/s directional fling.
- Preserve direct tap, outside tap and system Back behavior in the same focused test.

## Resolution evidence

The shared owner is corrected before repeating the focused suite.
