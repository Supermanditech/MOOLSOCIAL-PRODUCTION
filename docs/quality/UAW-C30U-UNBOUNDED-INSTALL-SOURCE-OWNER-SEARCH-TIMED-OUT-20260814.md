# UAW C30U unbounded installer-source owner search timed out

Date: 2026-08-14

## Incident

A read-only search for `get-install-source` included executable script roots,
the full regression registry and the complete quality archive. It timed out
with exit 124 after partial matches. Those partial matches are not accepted as
a complete owner inventory.

## Prevention

Search only the exact `scripts` and `tmp` executable roots. Read prior durable
incidents separately from their already located bounded line regions. Never
include large memory archives in a repair-owner lookup when the current script
owner is already known.

No source, release artifact, Google Play state or OPPO state changed.
