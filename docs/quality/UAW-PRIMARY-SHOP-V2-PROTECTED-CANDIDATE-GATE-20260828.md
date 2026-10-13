# UAW-PRIMARY-SHOP-V2-PROTECTED-CANDIDATE-GATE-20260828

State: `founder_authorized_exact_candidate_protection`

- Work ID: `shop-v2-protected-candidate-gate-20260828`.
- Task: `/root/codex_auth_shop_v2_protected_candidate_gate_20260828`.
- Branch: `work/codex-auth/shop-v2-protected-candidate-gate-20260828`.
- Candidate implementation: `e383eb8558492c947aa1dabbbd7341ab6ce32e38`.
- Base gate-ready tag:
  `moolsocial-reconciled-debug-baseline-v7.4.1-gate-ready-20260828`.

## Outcome

Buy protection and Brand integrity admit only the exact tested Shop/profile
implementation commit while retaining all v7.4 and historical protections.

## Boundaries

- No application, test, reference, backend, device or configuration change.
- Candidate context requires exact commit ancestry, exact protected inventory,
  exact protected owner bytes and the already qualified Buy structure.
- Any later Buy, profile, Social, Chat or brand drift fails closed.

The protected overlay is required before the unique `CursorUiReview` r61.5
build and Redmi install.

## Verified result

- Candidate implementation: `e383eb8558492c947aa1dabbbd7341ab6ce32e38`.
- Protected Buy: `47` runtime files, tree
  `23267fc722cad9dadab0ac8455be6368ef72de70888d01af4b9b41a4a06668a0`.
- Protected Social: `231` files, tree
  `52ef43844548757e9f89cd033198a3be00567fac5a792899f5c7842acba1ce4b`.
- App Brand integrity: passed.
- Approved UI reference and production locks: passed.
- Parent host replay: `100` tests passed with one intentional skip; analysis
  clean; generated support restored; exactly three implementation owners.
