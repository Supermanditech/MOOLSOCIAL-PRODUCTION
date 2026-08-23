# C27C visual-token test launcher-hit owner recurrence

## Observation

After removing synthetic `extendBody: true`, the large visual-token loop still
hit-tested the body colour owner at the compact launcher centre. The first
diagnosis was therefore incomplete; the panel again remained closed while the
separate reduced-motion drag interaction test passed.

## Cause

The visual-token matrix coupled its presentation assertions to a synthetic
pointer hit whose ownership is unrelated to those assertions. The existing
C26C test and the second C27C test already own real tap/drag behavior.

## Permanent prevention

Presentation-only switcher matrix tests invoke the already-tested launcher's
`InkWell.onTap` callback directly, then assert the rendered overlay. Pointer,
gesture, outside-tap and Back behavior remain in dedicated interaction tests so
one harness concern does not create false presentation failures.

## Resolution evidence

The second exact hit trace was retained and this recurrence registered before
changing the visual-token harness.
