# C30T regression entry guessed machine-state path

Date: 2026-08-13

The second memory-gate replay rejected the new reconciliation registry entry because it referenced `config/apk-regression-gate-state-c30t.json`, a nonexistent historical-style path. The exact C30T build machine-state owner is `config/play-internal-aab-regression-gate-state-c30t.json`.

The failure log is retained unchanged. Permanent prevention: inventory exact C30T config filenames and validate every new registry evidence/gate path in one bounded structural pass before replaying the memory checker.
