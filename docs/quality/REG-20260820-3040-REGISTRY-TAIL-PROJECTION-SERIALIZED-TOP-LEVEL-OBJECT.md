# REG-20260820-3040 registry tail projection serialized top-level object

## Observed failure

A registry-tail diagnostic emitted an unbounded serialization of the complete
registry instead of one bounded tail entry. The output is rejected.

## Root cause

The registry JSON has one top-level object containing an `entries` array. The
diagnostic wrapped the top-level object with `@(...)`, reported count one, and
serialized that complete object as the alleged final entry.

## Impact

- no repository, provider, build, Play, OPPO, account or device state changed;
- no credential or private value was emitted;
- the unbounded diagnostic is not accepted as registry evidence.

## Prevention and authorized retry

Project only `@($registry.entries)`, prohibit full-object serialization, and
emit only bounded scalar count/ID/SHA fields required by the caller.
