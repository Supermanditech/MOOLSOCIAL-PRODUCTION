# C26D new test path protected Social inventory rejection

## Observation

The protected Social inventory increased from 178 to 179 solely because the new universal shared-shell test filename contained `social`.

## Cause

The protected gate intentionally selects test paths containing `social`, `youtube` or `screen04`.

## Permanent prevention

- Give cross-family shared-shell tests neutral ticket-scoped filenames.
- Do not alter or reseal the protected Social baseline for a naming accident.
- Run the protected Social gate after the path correction.

## Resolution evidence

The test is moved, without content change, to a neutral C26D universal filename before gate retry.
