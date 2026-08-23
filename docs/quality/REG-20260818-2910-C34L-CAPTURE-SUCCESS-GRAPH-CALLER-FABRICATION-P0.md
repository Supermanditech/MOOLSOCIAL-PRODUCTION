# REG2910 — C34L capture success graph was caller-fabricable

## Incident

Independent PRE-AAB FIX2 audit proved that capture contract v2 binds only
role/path/SHA/bytes/media type and has no production capture producer. The
Play, OPPO and journey final writers accept caller-supplied success switches,
counts and self-declared producer/session/nonce/artifact claims. A caller can
therefore construct a hash-consistent but unobserved success graph.

## Impact

- No C34L Play, OPPO or journey success evidence is accepted as authoritative.
- C34L remains selection-only and all build/upload/install/device authorities
  remain held.
- No build, browser, Play, OPPO, journey, private/account, secret or external
  action occurred during detection.

## Root cause

FIX2 strengthened immutable artifact identity without assigning observation,
session creation, source binding and receipt creation to one production owner.
The final writers compared caller claims with artifacts whose producer and
contents were also caller-authored.

## Prevention

- One production capture producer owns observation, session/challenge,
  artifact/manifest/receipt creation and immutable journal chaining.
- Bind the producer script hash, sealed-source manifest, exact current
  state/aggregate/artifact/vector and authoritative source-owner receipts.
- Production final writers accept only an exact producer receipt path/SHA/bytes
  and derive all results; no success boolean or count is a production input.
- Fixture adapters are accepted only in a distinct parameter set under one
  unique confined fixture run root and are impossible in production.
- Missing production adapters fail closed with one literal adapter id.

## Disposition

Registered before FIX3 implementation. C34L remains selection-only.
