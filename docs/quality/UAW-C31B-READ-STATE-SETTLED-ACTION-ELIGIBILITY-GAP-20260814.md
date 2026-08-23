# C31B read-state settled action eligibility gap

Date: 2026-08-14
Registry ID: `REG-20260814-2129-C31B-READ-STATE-SETTLED-ACTION-ELIGIBILITY-GAP`

The first C31B read-state addition left reply and reaction guards checking exact `delivered` equality. A message advancing to `read` would therefore lose those valid actions. Source review caught the issue before tests.

The correction treats both `delivered` and `read` as settled message states and retains sending/failed exclusions. A focused regression must prove read messages keep reply and reaction actions. No live Chat or deployment occurred.
