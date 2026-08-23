# C30T pre-AAB qualifier coverage-closure finding — 2026-08-13

## Finding

The C30T pre-AAB qualifier did not run the read-only YouTube connection-state
regression or the seven-test Hosting/App Links suite. Its source fingerprint
also omitted the Hosting public source and relied on a partial hardcoded set of
C30T defect tickets. A source change or ticket outside those paths could
therefore escape the two-cycle fingerprint.

## Correction

The qualifier now includes the missing Flutter regression, runs the exact
Hosting/App Links suite with seven-pass and zero-fail markers, fingerprints all
27 Hosting public files plus `firebase.json` and the static test, and discovers
every `config/uaw-c30t-*-ticket.json` file dynamically. Cycle evidence records
the Hosting result and log SHA-256.

## Verification

The PowerShell parser, qualifier invariants, Hosting inventory, C30T ticket
inventory and all seven Hosting/App Links tests passed. Evidence SHA-256:
`517C30CCC00C98E603FFDDD557D4399EB9A62B4F16629058D4888FBFA5E1B944`.

The full live qualifier was deliberately not run: the live owner-connect and
Hosting prerequisites remain held. No provider, Hosting, build, Play, OPPO or
communication state changed.
