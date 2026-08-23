# UAW C30T Social backend filename-pattern no-match rejection — 2026-08-13

## Outcome

The Create expiry audit tried to discover backend owners by filtering filenames
for `social.*content|content.*social`. No backend filename matched that naming
assumption, and ripgrep exit 1 caused the command to fail after the mobile model
output.

The combined result is incomplete. No source or external state changed.

## Permanent prevention

Discover backend owners from exact operation/schema symbols within the proven
backend source root, normalize an optional filename-filter no-match, and only
then read the returned exact files. Do not assume provider symbol names are
encoded in filenames.
