# UAW C30U Windows rg literal wildcard path rejection

Date: 2026-08-14

## Incident

A read-only successor-seal owner lookup passed
`config/play-internal-*c30u.json` as a positional path to ripgrep on Windows.
Windows rejected that literal filename and ripgrep returned exit 1 after
printing matches from the other valid paths.

## Prevention

Use the two exact known JSON owner paths explicitly, or search the existing
`config` directory with an `--glob` selector. Do not treat useful partial output
from a nonzero command as a complete inventory.

The command did not mutate source, evidence, machine state, release artifacts,
Google Play or the OPPO device.
