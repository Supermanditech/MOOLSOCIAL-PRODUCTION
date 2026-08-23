# C23H deep-untracked dirty-inventory rejection — 2026-08-09

## Observed rejection

The first dirty-tree fingerprint forced `--untracked-files=all`. Git attempted
to descend through large retained browser-evidence trees and emitted multiple
filename-too-long warnings. The reported 52,659-entry fingerprint is rejected
even though Git returned zero.

## Permanent prevention

Use the established default path-safe porcelain inventory: it records every
tracked change and each untracked owner without recursively traversing
protected evidence directories. Capture and reject stderr warnings, sort the
records, and hash their LF-joined UTF-8 representation. No retained file is
deleted or altered.
