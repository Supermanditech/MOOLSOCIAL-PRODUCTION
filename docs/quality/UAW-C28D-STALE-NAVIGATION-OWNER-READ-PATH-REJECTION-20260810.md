# C28D stale navigation-owner read-path rejection

- Date: 2026-08-10
- Phase: device-gate owner inventory
- Rejection: a read-only command searched the live source successfully, then
  attempted to read two guessed legacy filenames that do not exist.
- Product/device effect: none; the command made no mutations and did not open
  build or install authority.
- Root cause: guessed owner filenames were appended to the same command instead
  of resolving exact paths from the preceding `rg` result.
- Prevention: use `rg --files` or the exact live search result before reading an
  owner; never assume a historical shared-navigation filename.
