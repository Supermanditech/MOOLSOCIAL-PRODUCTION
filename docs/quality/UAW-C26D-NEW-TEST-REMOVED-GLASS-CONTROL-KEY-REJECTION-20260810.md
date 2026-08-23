# C26D new test removed glass-control key rejection

## Observation

The new Social/Shop conformance test copied C25 `glass-control` keys and failed before exercising the approved C26 rail.

## Cause

The completed C26B shared owner was not used as the key authority.

## Permanent prevention

- Use current `moolsocial-local-<id>-selection` control keys.
- Assert the rail contains neither BackdropFilter nor horizontal scroll.
- Do not reintroduce glass cells to satisfy predecessor tests.

## Resolution evidence

The C26D test is migrated before its focused retry.
