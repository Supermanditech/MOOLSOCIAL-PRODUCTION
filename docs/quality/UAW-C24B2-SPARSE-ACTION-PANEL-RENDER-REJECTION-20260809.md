# C24B2 sparse action panel render rejection — 2026-08-09

## Rejection

The first OPPO-class host render of the fixed Home hub is rejected. Its selected-family card expands two action rows through all remaining height, so the first row sits near the top, the second near the bottom, and the large empty middle reads as unfinished rather than restrained.

## Registered cause

`_MoolSelectedFamilyPanel` nested `Expanded` around the row collection and around each row. Flutter therefore divided the remaining panel height between rows instead of sizing the group from its content.

## Required correction

- Keep the selected-family card top-aligned and content-driven.
- Keep every direct action at one shared minimum tap height with uniform two-column spacing.
- Render two actions as one row and three-to-four actions as two compact rows.
- Leave unused viewport space outside the card; never stretch sparse actions for symmetry.
- Re-capture and visually inspect the OPPO-class render before C24B2 qualification.
