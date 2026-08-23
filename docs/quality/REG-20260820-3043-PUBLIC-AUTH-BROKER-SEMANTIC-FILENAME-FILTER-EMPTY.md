# REG-20260820-3043 public-auth broker semantic filename filter empty

## Observed failure

A bounded `rg --files` pipeline filtered backend filenames only for semantic
`public/auth` combinations and returned no owner. No source lookup followed.

## Root cause

The production broker can be exported from a generically named module, so a
semantic filename constraint is not a reliable owner-discovery algorithm.

## Impact

- no repository, source, provider, build, Play, OPPO or device state changed;
- no broker evidence was accepted;
- no retry occurred before registration.

## Prevention and authorized retry

Enumerate only the bounded `backend/functions/src` filename set, verify literal
owners, and then search content within those existing files.
