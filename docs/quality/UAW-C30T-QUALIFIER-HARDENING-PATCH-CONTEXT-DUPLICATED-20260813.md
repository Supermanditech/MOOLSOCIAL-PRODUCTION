# C30T qualifier hardening patch context was duplicated

Date: 2026-08-13

The first patch intended to add exact live accepted-review flag checks expected the existing YouTube revision assertion twice. It exists once. `apply_patch` rejected the patch atomically, and readback proved neither the state-property addition nor qualifier change occurred.

Permanent rule: locate target lines with `rg`, inspect the exact current block, use unique current context, and verify no partial mutation before retrying a failed multi-file patch.
