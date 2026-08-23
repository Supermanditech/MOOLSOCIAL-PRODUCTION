# C29N stale fixed-54px protected navigation assertions

Date: 2026-08-11
State: resolved; permanent prevention active
Regression: `REG-20260811-1228-C29N-STALE-FIXED-54PX-PROTECTED-NAVIGATION-ASSERTIONS`

## Preserved observation

The second C29N cycle 1 attempt passed ticket, lock, format, full Flutter
analysis, the C29N focused cases and the formerly failing complete Screen 04
fitment matrix. Nine inherited navigation assertions then failed, beginning in
C27B, because they required every rendered fixed cell to remain 54 pixels even
at the newly supported three-cell 320-pixel rail and did not inventory the new
right-edge Chat control. No qualification artifact or runtime mutation occurred.

## Prevention

Protected navigation tests now use
`MoolLocalNavigationTokens.destinationFixedCellWidthFor(viewportWidth)` for
rendered geometry, retain the 54-pixel constant as the wider default, and assert
that Chat is the fixed right-edge companion. The complete set remains sealed in
both C29N qualification cycles.
