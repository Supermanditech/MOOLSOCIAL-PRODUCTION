# Store catalogue entry — CAT-STORE-01

Founder request: begin the Store product catalogue journey from the right-side Store rail, Add products. Store-specific consumer data must originate from owner-published information.

## Baselines and handoff read

- Start: installed integration `21977bff27cf22bfadb50f592a635355bb80574e`.
- Cursor handoff: `c4365373f2c34af0f240377c6a91726ffb8097dc`, remotely verified. Read current HANDOFF.md, current DEFECTS.md and all PUBLIC-DATA.csv rows: 271 total, including 200 catalogue mappings.
- Cursor application drafts and C04/C06/C07 remain separate and unqualified here. No Cursor integration performed.
- New isolated branch: `work/codex-ui/store-product-catalogue-20260916`. Sparse checkout avoids duplicating historical APKs after a full checkout ran out of space and Git rolled it back. Existing checkouts were untouched.

## Implemented scope

Store rail Add products opens a searchable identity picker with barcode scanning and explicit manual entry. Existing Store offers reopen without overwriting their stock/price; different packs remain distinct. A newly selected master identity starts with zero owner cost/price/stock and private visibility until the owner completes it. Scanner cancellation/failure does not create a product.

The reused editor captures Store identity when opened and rejects saves after a Store switch. Duplicate store SKUs are rejected without stock mutation. Public-toggle eligibility and editor eligibility now both check actual canonical product identity; replacing a title/brand/pack/variant/category/barcode cannot retain canonical eligibility merely by keeping an ID. Blank origin no longer silently becomes India. Public projection no longer invents a Verified retailer claim. The editor explains that customer preview eligibility is not connected live publication.

This is the first owner-entry ticket, not completion of the entire 200-field publication contract. Existing editor/local operational-save behavior is reused. No live publication provider, durable server acknowledgement, cross-device synchronization or upload service is asserted.

## Validation

- Seven focused picker/model tests passed: private initialization; retained existing offer; explicit manual path from unmatched scan; scanner failure recovery; distinct packs; landscape with keyboard; canonical identity/trust claim.
- Store right-rail navigation/return test passed.
- Three connected owner tests passed: save new offer privately; duplicate SKU rejection; workspace-switch rejection with both Stores' data preserved.
- Static analysis of changed Dart owners and tests passed. The picker and its tests were re-analyzed after the final layout adjustment: no issues.
- A test exposed late Store-ID initialization; corrected to initState. Landscape keyboard test exposed a 22px overflow; corrected with short-viewport scrolling and retested successfully. Earlier failed test attempts are not passes.
- No new APK/device or live-provider qualification. No repeated full regression or governance-only build checks.

## Remaining catalogue tickets / dependencies

1. Owner product details and exact SKU/variant media: implement editable fields from the Cursor mapping, reuse existing media admission contracts, preserve private versus public boundaries, and provide a faithful preview. A photo description is not an uploaded product image.
2. Publication contract: store+SKU identity, separate draft and acknowledged public revisions, allowlisted DTO, publish/update/unpublish, owner authorization, offline/retry/idempotency and failure retention. Reuse existing services; private operational snapshots must never become public DTOs.
3. Consumer provider wiring: bind acknowledged owner publications into Store/Shop/catalogue/detail and price/availability consumers with freshness and withdraw admission checks while retaining query/cart/history context.

Platform verification, ratings, grants and canonical facts retain platform authority. Store-specific offers derive from owner input. Customer/ledger data, KYC, purchase cost, margin, credentials and internal notes stay private. The YouTube r60.95 review cutoff remains unchanged.
