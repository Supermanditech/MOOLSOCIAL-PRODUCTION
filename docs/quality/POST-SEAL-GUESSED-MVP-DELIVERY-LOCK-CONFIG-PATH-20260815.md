# Post-seal guessed MVP delivery-lock config path

An ancillary backlog search passed the invented path
`config/mvp-delivery-discipline-lock.json` to ripgrep. That file does not
exist, so ripgrep returned an OS path error after printing matches from the
other literal owners.

No state changed and no partial output is qualification evidence. REG-2294
must be registered before any related lookup. The exact lock owners must be
read from `scripts/check-mvp-delivery-discipline-lock.ps1` or resolved through
`rg --files`; a remembered filename is not an owner.
