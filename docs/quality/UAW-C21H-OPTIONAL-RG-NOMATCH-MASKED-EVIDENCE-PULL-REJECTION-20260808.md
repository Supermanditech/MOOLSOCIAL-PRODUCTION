# C21H optional rg no-match masked evidence pull rejection

Date: 2026-08-08

Both `17-current-start.png` and `17-current-start.xml` were pulled successfully and hashed. An optional trailing ripgrep expression assumed that `text` appeared before `bounds` in every UIAutomator node; it found no match and returned exit 1, masking the successful required operations.

The existing local captures are retained exactly. Subsequent UI inspection uses parsed XML nodes and keeps optional exploration from determining the required capture result.
