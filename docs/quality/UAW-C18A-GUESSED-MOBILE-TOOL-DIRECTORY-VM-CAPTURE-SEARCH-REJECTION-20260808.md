# UAW C18A guessed mobile-tool directory VM-capture search rejection — 2026-08-08

## Rejected search

The first lookup for the earlier VM-synchronized capture method combined
verified R50 evidence files and repository scripts with the guessed path
`apps/mobile/tool`. Ripgrep rejected that nonexistent path, so the aggregate
search result is not used to conclude whether a reusable capture owner exists.

No production, reference, build, install or device state was changed.

## Prevention

VM-capture discovery must derive candidate paths from `rg --files` under
verified literal roots. Evidence-file reads and source inventories run as
separate commands, and a missing path invalidates only its own search rather
than being combined with otherwise useful output.
