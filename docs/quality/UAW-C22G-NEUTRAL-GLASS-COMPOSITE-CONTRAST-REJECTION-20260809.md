# C22G neutral-glass composite contrast rejection

- Observed: 2026-08-09 after the four stale cumulative test owners were
  migrated to C22 geometry, typography and chroma ownership.
- Failing result: six family cases reported 3.5557:1 white-label contrast
  where at least 4.5:1 is required: Social and Buy in C20D, and Eat, Ride,
  Book and Work in C20E.
- Root cause: `neutralGlassTop=0x780D1326` and
  `neutralGlassBottom=0x5C050816` transmitted too much bright destination
  luminance; the 0.78 selected inner-emission maximum could reduce real
  selected-state contrast further.
- Required repair: a narrow runtime ticket must retain nonopaque transparent
  glass and visible destination transmission, keep all family color inside
  the capsule, and freeze a composite 4.5:1 minimum across representative
  light, orange, media and navy backgrounds for every family accent.
- Qualification: C22G cycle 1 and the failed focused run are rejected. No
  runtime repair is authorized by C22G itself.
- Device effect: none; r60.20 remains installed and unchanged.
