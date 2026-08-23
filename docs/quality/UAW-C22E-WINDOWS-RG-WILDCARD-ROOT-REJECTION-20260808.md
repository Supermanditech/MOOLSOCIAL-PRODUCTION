# C22E Windows rg wildcard-root rejection — 2026-08-08

The first C22E reverse-U contract search passed wildcard positional roots on Windows and was rejected before reading files. REG-20260808-535 records the recurrence; the corrected search uses literal `config` and `docs/quality` roots with `--glob` filters.
