# C24G repository-CWD used mobile test alias rejection — 2026-08-09

A C24G owner-key inventory ran from the production repository but included the
mobile-relative `test` alias instead of `apps/mobile/test`. Ripgrep returned
valid production matches and a missing-path error, so the partial output is not
a qualifying inventory.

This is a second repeat of the path/CWD class and is separately registered.
Repository-root commands use `apps/mobile/...`; mobile-root commands use
`lib/...` and `test/...`. Inventory commands may not mix them.
