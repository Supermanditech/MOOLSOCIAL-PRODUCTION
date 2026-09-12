# Work Store r62.56 — OPPO closure for defects 56–58

## Candidate identity

- OPPO: `CPH2375`, serial `2b3e0f71`
- Package: `com.moolsocial.app.runtime`
- Version: `1.0.0-r62.56-runtime` (`2026090312`)
- APK SHA-256: `0E6D99484C4D25908F50912A73478D148AE4000CED61F2C448E9820CE0E6D67A`
- Codex implementation commits: `47d3e15eb11d80c9a1fae96752f118edf37f0c06`, `080c398b48ba0a87927e66de392893b435665d24`

## OPPO result

- **Defect 56 passed:** the empty customer field exposes native resource ID `work-order-customer`, semantic value `Not entered`, and no longer reports `NAF=true`. Visible editing and controller value remain unchanged.
- **Defect 57 passed:** one Android Back from the exact Workspace Buy product restores Storefront directly; the generic Shop catalogue is not inserted.
- **Defect 58 passed:** completing Store search clears the inactive term and restores `Search your store` on the dashboard.

## Verification

- Focused analyzer: clean.
- Full Work layout + Buy route regression: 48 active tests passed; 48 evidence-only tests skipped.
- Focused native semantics regression: passed.
- OPPO native hierarchy evidence:
  - `artifacts/device/work-store-r62-56-oppo-review-20260903/oppo-audit/01-native-field.xml`
  - `artifacts/device/work-store-r62-56-oppo-review-20260903/oppo-audit/02-search-cleared.xml`
  - `artifacts/device/work-store-r62-56-oppo-review-20260903/oppo-audit/03-direct-buy-back.xml`

## Remaining separate owner

The shared Buy scanner capture/status defect remains assigned to Cursor's existing Buy owner. No Cursor Buy scanner/session/screen source was modified by Codex.
