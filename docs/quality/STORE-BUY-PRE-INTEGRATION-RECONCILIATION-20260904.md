# Store-Live and Buy pre-integration reconciliation

Date: 4 September 2026

## Exact identities

- Shared baseline: `21118db8c061b085fe60ac419d52ee0fd83fcde2`
- Store-Live tip: `aa335eb1497d77c859e7d34b549716350612c5c8`
- Cursor Buy tip: `fd55d1cfffa5ed10f753f2ed24461ef9ac6a9a5d`
- Store-Live history: 57 commits and 107 changed paths from the shared baseline.
- Cursor Buy history: 41 commits and 429 changed paths from the shared baseline.
- Cursor continuation range: 35 commits and 415 paths from `958e767e6f910e40b8f475d99173011f0f07ea78`.

The shared baseline is the merge base and an ancestor of both accepted tips. Codex UI/UX `38e6841b8d67232229509c9267aafb5daf74ad58` and Core `b758c5f6771a0c8e39d127c6de1ef76809e37049` are already ancestors of Store-Live and must not be integrated separately.

Rejected Cursor tips `59f63db15d2aeb970dcfc5b4d39eaf312ca76168` and `0df24cc11f06ec5032a0f6def454c03b41c09e30` are ancestors of neither accepted tip.

## Overlap

There is no product-source overlap and no test overlap. Exactly three paths overlap and conflict:

1. `config/codex-development-regression-registry.json`
2. `config/codex-subagent-coordination-policy.json`
3. `scripts/check-codex-subagent-coordination-policy.ps1`

The conflict-qualified repair must preserve the registry and claim union. It may not select either parent wholesale and may not manually edit any automatically merged product or test owner.

## Dependency and payment preservation

Cursor UAT-BUY-073 blobs:

- `3ec6c1f88c1f4a0a616362bb619be80ada2b31b8 apps/mobile/.dart_tool/package_config.json`
- `af3c22082d951a5ce701ba6eef704440affa8efd apps/mobile/.dart_tool/package_graph.json`
- `4e565f03f24729e64350c49506ef1739f5ac47a4 apps/mobile/.flutter-plugins-dependencies`

Cash on Delivery remains Shop-only, requires every Checkout line to be Shop, is limited to ₹5,000 and remains validated at continuation and submission. Wholesale/Bulk Purchase Order context remains unchanged.

## Planned topology

1. Produce one remotely verified two-parent repair tip from the exact Store-Live and Cursor Buy commits.
2. Resolve only the three coordination conflicts.
3. Run focused coordination, dependency, Work, Store, Buy, COD, Purchase Order, router and Chat-boundary regressions.
4. Admit only the qualified repair tip into a fresh integration branch through one automatic no-FF merge.
5. Build no APK until combined integration gates pass and separate authority is granted.
