# REG2913 — C34L concurrent regression-number allocation collision

## Incident

On 2026-08-18, two concurrent C34L FIX3 streams independently allocated numeric REG2910. One recorded the source-map `rg` argument-position overmatch; the other recorded the capture caller-fabrication P0. Full string IDs differed, so JSON parsing and the existing memory gate did not reject the duplicate numeric allocation. REG2911 was then allocated normally before detection.

## Impact

- Durable regression numbering was ambiguous until correction.
- No implementation, candidate, seal, cycle, build, Play, OPPO, browser, private/account, device, secret or external action relied on the ambiguous number.
- Both FIX3 implementation streams stopped before further code work.

## Correction and prevention

- Keep the source-map incident as REG2910.
- Correct the caller-fabrication P0 registry ID/evidence owner to REG2912.
- Register this coordination incident as REG2913.
- Only the primary agent allocates future regression numbers; subagents report incidents and wait for the literal ID/path.
- Add a future registry gate rejecting duplicate numeric prefixes even when full string IDs differ.

## Disposition

The original duplicate-number P0 document remains preserved but is no longer the registry evidence owner. No deletion or history rewrite occurred.
