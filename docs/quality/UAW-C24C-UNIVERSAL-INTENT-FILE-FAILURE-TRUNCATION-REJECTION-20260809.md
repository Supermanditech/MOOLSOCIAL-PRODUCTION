# C24C universal-intent file failure truncation rejection — 2026-08-09

The isolated universal-intent file still contained many independent journeys.
It ended with five failures, but the 40-line tail retained only the last Book
Doctor case, which expected removed `mool-root-selected` and an intermediate
Home owner. The first four diagnostics were not visible.

REG648 requires exact plain-name isolation. No change is inferred for unseen
failures; each is diagnosed and registered before correction.
