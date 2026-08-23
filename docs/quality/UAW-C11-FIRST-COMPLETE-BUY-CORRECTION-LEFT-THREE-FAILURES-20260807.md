# C11 first complete-Buy correction left three failures

- Regression: `REG-20260807-257-C11-FIRST-COMPLETE-BUY-CORRECTION-LEFT-THREE-FAILURES`
- State: `resolved_gate_active`
- Date: 2026-08-07 IST

## Observation

The first functional correction reduced the complete-Buy failure inventory
from twelve functional failures to three. The focused five-file run passed 84
tests and explicitly excluded one protected golden reference, but exited with
three failures. The second protected golden remains separately expected in its
own file. No APK build or OPPO mutation occurred.

## Required correction

Use the bounded JSON reporter on the exact affected files to identify the
three remaining names and errors. Register and correct the smallest rightful
product or test owners, then re-run the focused set and two complete Buy
functional cycles before closing this regression.

## Resolution

The remaining compact no-results, product-detail reachability and Assist
journeys passed focused qualification. The five affected files then passed 87
tests with one protected-reference exclusion, followed by two complete Buy
functional cycles of 360 passes, 20 skips and zero failures each.
