# Buy C24F runtime-manifest truncated saved-store SHA-256

Date: 15 August 2026
Regression: `REG-20260815-2261-BUY-C24F-RUNTIME-MANIFEST-TRUNCATED-SAVED-STORE-SHA256`

The immutable manifest `artifacts/quality/buy-protected-candidate-c24f-connected-back-20260809-02/RUNTIME-MANIFEST.txt` contains a 62-character digest for `apps/mobile/lib/features/buy/buy_v2_saved_products_store.dart`:

`044da1e06b33bbad7d0c31f725ee6c41fe9e563f6c6f5006079bbb06b7ed94`

The current file computes to the complete 64-character SHA-256:

`044da1e06b33bbad7d0c31f725ee6c41fe9e1e563f6c6f5006079bbb06b7ed94`

This finding is an immutable-evidence defect, not proof of current source drift. The retained manifest is not edited. Exact generation-history and protected-tree reconciliation are required before that row can be used in a founder baseline decision.
