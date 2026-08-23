# C24I omission-audit guessed test-root rejection

Date: 2026-08-09

The first bounded omission search correctly queried the C24 runtime owners and `apps/mobile/test/ui_v2`, but also guessed a conventional `apps/mobile/test/features` root that does not exist. Ripgrep reported the path error; a downstream PowerShell pipeline masked its native nonzero exit.

The search output is not admitted as final omission evidence. No runtime, APK or OPPO application state was changed. The retry may use only exact inventoried test roots and must validate ripgrep's native exit before formatting output.
