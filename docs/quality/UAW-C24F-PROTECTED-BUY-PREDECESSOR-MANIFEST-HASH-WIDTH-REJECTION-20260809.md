# C24F protected Buy predecessor manifest hash-width rejection — 2026-08-09

The first per-file delta helper stopped because the retained C24B3/C24D
`RUNTIME-MANIFEST.txt` line for `buy_v2_saved_products_store.dart` has a
62-character hash rather than a complete SHA-256 value. The existing Buy gate
does not consume that auxiliary manifest; it enforces the exact 43-owner
aggregate tree recorded in `BASELINE.json`.

The malformed evidence is preserved unchanged. The C24F successor inventory
will be generated mechanically, validate every per-file hash width and compute
its aggregate tree from the same portable line-ending policy.
