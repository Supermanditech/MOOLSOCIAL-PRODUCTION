# C30N Feed error-copy exact-search no-match rejection

- ID: `REG-20260812-1476-C30N-FEED-ERROR-COPY-EXACT-SEARCH-NO-MATCH-REJECTION`
- Date: 2026-08-12
- Scope: local read-only Feed state-owner discovery
- Result: no exact match; no build, install, cloud or content mutation occurred

The first exact lookup for the rendered heading returned no source match. C30N
treats the result as explicitly absent and does not guess an owner. The retry
uses a shorter exact fragment already visible in the captured hierarchy and
reads only the returned literal path.
