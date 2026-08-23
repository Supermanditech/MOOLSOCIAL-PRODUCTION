# C26F Back dispatch awaited frame animation deadlock

## Observation

The Back stress suite stopped progressing because `handlePopRoute` awaited a listener callback that awaited an AnimationController reverse; no test pump could run until the dispatch returned.

## Cause

Back event acknowledgement was incorrectly coupled to frame-driven visual completion.

## Permanent prevention

- Start the close animation without awaiting it inside the Back listener.
- Return `Future<bool>.value(true)` immediately when the switcher owns the event.
- Let the caller/test pump the finite 180ms close.
- Keep reduced motion immediate.

## Resolution state

Fix active; the hung process was terminated and no qualification result was claimed.
