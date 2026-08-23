# C17H overgeneralized top-inset semantic tap transform rejection

Adding the 82-pixel display cutout inset to the `Open Workspace` subaction center moved the tap from the subaction rail into the physical main rail, selecting Book/Doctor. This proves UIAutomator content/subaction bounds are already physical even though the hierarchy's bottom extent clips the main rail.

The helper now uses literal semantic centers for subactions ending at y=1424 and a separate measured physical y=1480 only for clipped main-family buttons beginning at y=1432. Every result is inventoried before evidence capture.
