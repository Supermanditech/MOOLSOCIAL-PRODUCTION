# C24I repeated deep-untracked dirty-inventory rejection

Date: 2026-08-09

The first C24I compact dirty-tree command forced `--untracked-files=all`. This repeated permanent regression REG598: Git descended into retained browser evidence, emitted filename-too-long warnings and returned an inadmissible 52,961-entry inventory.

The result and its hash are rejected. No repository file was removed, no APK was built or installed, and the OPPO r60.22 predecessor remains unchanged.

C24I uses only the established warning-free default porcelain inventory, which covers every tracked change and every untracked owner without recursively traversing protected evidence directories. Records are sorted and hashed as LF-joined UTF-8.
