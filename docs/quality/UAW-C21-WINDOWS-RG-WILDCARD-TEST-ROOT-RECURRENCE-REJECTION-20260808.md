# C21 Windows ripgrep wildcard test-root recurrence rejection — 2026-08-08

The first C21E test inventory passed `apps/mobile/test/uaw_personal_mvp_*subaction_professional_conformance_c16*` as a Windows ripgrep root. Windows treated the wildcard root as invalid and ripgrep returned error 123. The source-owner inventory had already confirmed the real family actions, but the failed test search provides no accepted test inventory.

All Windows ripgrep searches use literal existing roots and `--glob`, or select exact files from `rg --files`. Wildcards never appear in a search-root argument.
