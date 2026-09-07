# Fresh Redmi Buy corrections — 5 September 2026

Ticket: UAW-CURSOR-BUY-REDMI-FIXES-V1-20260905. Classification: mvp_required.

## Authority and immutable starting point

Founder requests fresh Redmi real-user audit, registration of actual defects, then necessary Cursor-owned corrections one by one, local regression, a new review APK and original-sequence Redmi retest. Standing authority remains active; no GM CURSOR or stop instruction has arrived. WhatsApp remains prohibited. This serialized child starts from the clean, pushed, exact remote-equal audit checkpoint `a09a2ecccf1e701a60117bdf34aa6a732cb132e2`, descended from source correction `e2dd3bc706065fbc08d9c526c48e24374cd32e6e` and accepted combined baseline `f94cfd4752dd73b58a69568475803d6cf25cb8d0`.

Worktree: C:/GUARANTEED OUTCOME/MOOLSOCIAL-WORKTREE-CURSOR-buy-redmi-fixes-v1-20260905.
Branch: work/cursor-ui/buy-redmi-fixes-v1-20260905.
The audit branch remains preserved and does not mutate concurrently. No merge, integration, history rewrite, production/accepted checkout edit or Codex-owned source consumption.

## Minimum outcome and reuse assessment

Correct the existing customer journeys identified by fresh R66-UAT-001–035, preserving a separate reproduction/test/retest for every finding. This is not permission to add 35 screens or a new marketplace. The 35-row register in `docs/quality/cursor-buy-redmi-uat-v1-20260905/DEFECTS.md` remains authoritative; incomplete coverage and operational boundaries in UAT.md remain open, not passed.

Reuse existing catalogue, saved sheet, scanner, Buy session, cart, checkout, product/store views, comparison, orders and tracking. No new screen/route/backend owner is planned. Exact source/target actor and recovery are mandatory for each atomic slice:

| Initial sequence | Exact customer capability and required recovery | Findings |
|---|---|---|
| 1 | Retail/Wholesale buyer can keep or clear only their selected Saved collection; Back never deletes | 018 |
| 2 | Buyer can scan or enter a code with honest camera capability, empty-input feedback, readable keyboard actions and Back | 021/022/031 |
| 3 | Buyer can read current prices and tap scoped cart/actions at normal or enlarged text without hidden hit regions | 004/005/006/008/009/026/028/029 |
| 4 | Buyer can return through saved/store/product/cart/comparison/alerts to the actual origin without cross-scope leakage | 007/013/017/023/025/033/034 |
| 5 | Buyer can inspect compact product/recent/sparse-result information and recover filters without losing unique purchase facts | 003/014/016/020/030 |
| 6 | Review buyer receives collision-free local order identity and truthful address/progress/price/offer/basket/payment-state presentation | 002/010/011/012/024/027/032/035 |

Shared orientation (001), provider promise eligibility (019), authoritative per-item resolution (015), live supplier/payment/COD/courier adapters and actual preference persistence require explicit owner-boundary assessment. Implement only truthful Buy projection/fallback within this claim; do not invent commercial policy, real delivery, payment success or backend availability. Codex owns Workspaces, shared Chat/Care/routing and backend/native integrations.

## Exact claimed implementation owners

A claim is an upper bound mapped to the listed observations, not a requirement to edit every file. One coherent finding/slice is implemented at a time. Unused owners remain byte-identical.

- apps/mobile/lib/ui_v2/buy/buy_v2_catalogue.dart
- apps/mobile/lib/ui_v2/buy/buy_v2_screen.dart
- apps/mobile/lib/ui_v2/buy/buy_v2_views.dart
- apps/mobile/lib/ui_v2/buy/buy_v2_scanner.dart
- apps/mobile/lib/ui_v2/buy/buy_v2_design.dart
- apps/mobile/lib/features/buy/buy_v2_session.dart
- apps/mobile/lib/features/buy/buy_v2_models.dart
- apps/mobile/lib/features/buy/buy_v2_content_contracts.dart
- apps/mobile/lib/features/buy/buy_v2_order_resolution_contracts.dart

Focused existing tests (no historical golden replacement):

- apps/mobile/test/ui_v2/buy/buy_v2_saved_clear_sheet_motion_test.dart
- apps/mobile/test/ui_v2/buy/buy_v2_manual_code_sheet_motion_test.dart
- apps/mobile/test/ui_v2/buy/buy_v2_screen_test.dart
- apps/mobile/test/ui_v2/buy/buy_v2_responsive_product_grid_test.dart
- apps/mobile/test/ui_v2/buy/buy_v2_recently_viewed_test.dart
- apps/mobile/test/ui_v2/buy/buy_v2_cart_relevance_widget_test.dart
- apps/mobile/test/ui_v2/buy/buy_v2_scoped_cart_checkout_dock_continuity_test.dart
- apps/mobile/test/ui_v2/buy/buy_v2_checkout_cart_return_continuity_test.dart
- apps/mobile/test/ui_v2/buy/buy_v2_partner_catalogue_test.dart
- apps/mobile/test/ui_v2/buy/buy_v2_shopping_settings_test.dart
- apps/mobile/test/ui_v2/buy/buy_v2_shopping_alerts_test.dart
- apps/mobile/test/ui_v2/buy/buy_v2_product_continuity_test.dart
- apps/mobile/test/ui_v2/buy/buy_v2_honest_recovery_origin_continuity_test.dart
- apps/mobile/test/ui_v2/buy/buy_v2_product_decision_glance_test.dart
- apps/mobile/test/ui_v2/buy/buy_v2_product_compact_action_test.dart
- apps/mobile/test/ui_v2/buy/buy_v2_order_delivery_address_context_test.dart
- apps/mobile/test/ui_v2/buy/buy_v2_honest_order_motion_test.dart
- apps/mobile/test/ui_v2/buy/buy_v2_order_progress_test.dart
- apps/mobile/test/ui_v2/buy/buy_v2_order_resolution_test.dart
- apps/mobile/test/ui_v2/buy/buy_v2_search_result_recovery_test.dart
- apps/mobile/test/ui_v2/buy/buy_v2_discovery_refinement_test.dart
- apps/mobile/test/ui_v2/buy/buy_v2_product_variant_selection_test.dart
- apps/mobile/test/ui_v2/buy/buy_v2_wholesale_trade_decision_test.dart
- apps/mobile/test/ui_v2/buy/buy_v2_benefit_selection_continuity_test.dart
- apps/mobile/test/ui_v2/buy/buy_v2_product_benefits_preview_test.dart
- apps/mobile/test/ui_v2/buy/buy_v2_session_test.dart

Five existing audit documents remain claimed only for honest status/provenance updates in this child; their previous Git snapshots and all external capture triples remain immutable. New results owner: docs/quality/cursor-buy-redmi-fixes-v1-20260905/RESULTS.md.

## First atomic slice and test plan

R66-UAT-018: reuse `_SavedClearDecisionSheet`, `_confirmClearSaved`, existing Saved operations and motion. Preserve design/shape/colour/normal spacing. Make both complete 44dp-or-larger actions visible above Android system navigation using real layout constraints. Test 320/360/430dp widths, compact height, normal/140%/200% text, safe-area padding, reduced motion, Keep, Back, confirm and other-scope/cart preservation. Reproduce the current failure before source correction; then focused tests and two affected connected regressions. Future slice-specific results are recorded independently.

No source acceptance from semantics alone, no overflow suppression, no blind golden update and no duplicate state/navigation owner. Native command exits and complete logs must be retained. Fresh unexpected failures get an evidence/child record before retry; existing registered reproductions remain permanent.

## Device, build and completion limits

Existing installed r66.1 is review-only, package com.moolsocial.app.cursorreview, APK SHA 30A71FE8B6696BF51400FBED5A90C3179E25CE0A6153A998F5A041657C9D35C3. Its captured defects are not yet fixed on the phone. No current build authorization is consumed by implementation; each later candidate must pass the existing source-bound build gate and receive unique provenance/version.

Redmi TG8HCYTGGQT885OF only. No OPPO, WhatsApp, real payment/order/refund/supplier message/call, external recipient sharing, production app mutation, deployment or laptop/device shutdown. Preserve review data and restore temporary font/density/rotation settings. Live/unavailable backend states, physical optical decoding and untested cases stay explicitly unqualified.

Commit source/test/results atomically per slice, run mandatory gates, push and verify exact remote SHA equality. Register new shared-owner findings for Codex; do not integrate now. Founder final review remains required; neither this bootstrap nor a host-test pass is acceptance.

## Founder-authorized dependent-test ownership amendment

On 5 September the founder authorized Cursor to register the existing honest-order-motion test for R66-UAT-002/011, and confirmed that Codex received the coordination message. The claim grows from40 to41 owners, with no additional product, shared, native, backend or integration owner. The founder's morning resumption limits execution to the35 fresh Redmi observations and necessary children; the earlier no-GM statement above is historical, not current sequencing. Existing source and evidence commits remain intact.

One coordination-only checkpoint must have parent c6ffece62a6e4dea0810b88eb7fc98775c832fe6 and change exactly the coordination policy, this manifest, its local scope-state hash binding and the coordination gate. Its sole purpose is the exact test owner and safe admission while seven checksum-bound drafts remain unstaged. Do not commit those drafts in the ownership checkpoint; afterward the normal fully-staged atomic implementation and clean-handoff gates apply. Freeze all four coordination blobs after that checkpoint. Do not waive tests, alter the global registry, create a new worktree, touch Codex files or integrate. Run positive and fail-closed gate checks before the checkpoint; correct and qualify the dependent test afterward.

## Founder-authorized Social protection gate binding repair

The founder explicitly approved Annotation1's proposed coordination scope extension and directed continuation from the exact interruption through every pending Redmi finding. This supersedes the preceding four-blob freeze only for one atomic coordination repair after parent 0dc950ff1ba41a5a50808c5905bb8dd88e52448a. It adds scripts/check-social-protected-baseline.ps1 to the primary coordination claim; the Cursor executor retains its existing41 owners. The exact five changed owners are that Social checker plus the previous four coordination owners. No product, Social/backend/native source, registry, historical baseline, reference or integration owner is added.

Minimum mvp_supporting result: the existing Social protection checker recognizes the238 protected files inherited unchanged from accepted combined commit f94cfd4752dd73b58a69568475803d6cf25cb8d0 on this exact Redmi branch and its descendants. Reuse Test-SealedSocialOverlayCandidate so inventory equality and every protected byte remain mandatory. Preserve all legacy checks. Prove the actual checkout passes and wrong branch, missing ancestry, altered bytes, missing owners and extra owners fail. Verify PowerShell5.1 and7 compatibility. Freeze all five coordination owners after the repair checkpoint, keep ordinary feature commits fully staged and keep the same35 original Redmi observations and all existing test exclusions explicit.

The preceding failed Social gate and accepted-tree equality audit remain recorded as034-B in RESULTS.md; a successful successor does not erase them. During this approval resumption, one attempted coordination invocation used primary/baseline against the Cursor checkout and correctly failed with "production checkout branch or root changed" (native1). This repeats the already registered role-binding incident: repository gate role must be the recorded Cursor executor, even though the conversation is coordinated by /root. The corrected subagent/cursor_ui/implementation invocation passed with41 claims and4502 registry entries; no source write preceded that pass. Regression-memory implementation/none also passed with the existing EvidenceArchiveRoot. Do not repeat the rejected invocation or change the production checkout to accommodate it.

034-B-1 compatibility finding: actual Social protection passed on PowerShell7 and5.1, and all nine rejection fixtures passed on both hosts. The subsequent real5.1 coordination pre-commit failed native1 at the scope-object equality check. The new Get-Content calls had omitted explicit UTF8 decoding;5.1 defaults differ from7 for the existing Unicode scope text. Preserve this failed result and fix decoding inside the new amendment only, then require an actual5.1 positive pre-commit pass. Expected-value rejection fixtures alone do not prove the positive path on another host. A read-only discovery command also guessed a nonexistent core/navigation/app_router.dart; the subsequent rg --files discovery located features/journey01/journey_router.dart. This is a recurrence of the existing exact-path discovery prevention rule; no router file was edited.

034-B-1 second attempt remains failed: explicit file UTF8 alone did not correct native git-show decoding. Retained precommit51-2 receipt has native1 and stderr SHA A7EC08BBA781C303179FE06CEA84DF5B5C97D1A0660470B09C5D64A5B22E00D8. The actual5.1 diagnostic reports console codepage437, historical necessityProof non-ASCII codepoints915/199/244 versus correct file codepoint8211 (en dash). The earlier default-host diagnostic ran on7.6.5 and was not5.1 evidence. Read the two historical JSON blobs through an explicitly UTF8 native stdout stream inside this amendment; keep the existing objects and authorization checks unchanged. Evidence prefix r66-social-gate-repair-encoding-diagnostic1, native0, stdout SHA15B1DDD38E3F28C9C3696159231D2DD70019A47BF3AE6DB8A786A8E97486872A. Verify the final full positive gate on both hosts before sealing.

## Founder-authorized Redmi review preflight ownership amendment

The founder's continuing instruction to finish all35, test a fresh Redmi candidate, collect every device child and then implement them, together with Annotation1's approved coordination extension, authorizes the necessary R66-BUILD-001 repair. The original35 are locally qualified at d07559609ffad7371a6a98d765d4fefa186dc065; none is yet accepted on the fresh device candidate. Evidence-only parent3437dc9591256aabfd9c3fc6b3fb22cd0c6ccdba is clean, pushed and remote-equal. Four inherited boundary failures are retained in RESULTS.md; their failure is not a waiver.

One coordination-only admission with that exact parent changes only this manifest, its scope hash, the coordination policy and checker. Add exactly four existing checker owners to the primary claim: scripts/check-buy-protected-baseline.ps1, scripts/check-buy-backend-contract-boundary.ps1, scripts/check-buy-data-egress-boundary.ps1 and scripts/check-brand-integrity.ps1. The primary claim becomes10; Cursor remains41. No registry, runtime, backend, native, reference, historical baseline or other test owner is added. Freeze the existing five coordination/Social owners at this admission; preserve their entire earlier frozen history. The four newly admitted checkers may then be repaired and tested as a separate fully staged atomic slice with RESULTS.md.

The mvp_supporting minimum is an explicit non-promotable Redmi review qualification path bound to the exact locally tested source commit and accepted combined ancestor f94cfd4752dd73b58a69568475803d6cf25cb8d0. Keep the legacy/default production paths fail-closed. Require complete protected inventory and byte equality to the identified review source, constrain its accepted-baseline delta to the authorized Buy owners, and preserve unchanged backend/native/shared protection. Classify existing scanner completion, payment-URI projection, Saved storage and deliberate sharing seams from their actual accepted source; never admit new transport, fabricated commerce completion, clipboard reads or recipient actions. Preserve canonical brand and finite-motion checks while recognizing the inherited single theme canvas. A review-source checksum is not a founder-accepted baseline. Prove the actual positive path and wrong branch/ancestry/source/inventory negatives on PowerShell5.1 and7 before a unique guarded APK. Keep existing r66.1 evidence immutable; use distinct generated candidate/provenance artifacts and additive status references.

Pre-admission read incidents814b33 and2b57d4 assumed a globally unique /root text anchor even though the parsed activeClaims primary is unique; both failed closed without mutation. Bounded literal owner discovery and the exact activeClaims range resolve it. Future primary claim edits use that parsed collection and exact local owner hunk.

## Founder-authorized R4 landscape menu ownership amendment

Standing founder approval to extend necessary coordination scope and complete all original/child Redmi UAT defects includes child001-R4-A. Retained Redmi captures250/251 show the Mool switcher extending above the landscape safe area; Social is absent and Shop overlaps the status area. The minimum mvp_required repair is to keep every menu choice reachable within available app bounds at normal/enlarged text and portrait/landscape, with scrolling when needed, preserving destination selection, Back, outside-tap and downward dismissal. This does not authorize other-domain features or a replacement navigation design.

Add only apps/mobile/lib/ui_v2/universal/mool_global_navigation_v2.dart to the existing Cursor claim (41 to42 owners); reuse the already-claimed focused Buy tests and results. Primary coordination remains exactly10 owners. Amend only policy JSON, this manifest, its scope manifest hash and the coordination checker at the single parent89c7970c77629b615a6cb08c9b51946fedcb8cea, with subject ui(buy-redmi-fixes-v1-20260905): admit landscape Mool menu repair. That parent is the clean, pushed, exact-remote-equal Buy repair slice:717 full connected passes/3 intentional skips and126 scoped visual passes. Preserve historical admission blobs/history through that parent; verify the new single-owner claim and otherwise identical policy/scope, and freeze the exact four coordination owners after this one admission. No runtime, test or results owner belongs in the admission commit.

Prove actual pending implementation/pre-commit and post-commit checks on PowerShell5.1 and7, including rejected extra/missing claim, altered manifest/scope, wrong ancestry, history revision, extra dirty owner and pending handoff. Then implement the single shared owner, reproduce the landscape defect before repair and test all six choices, safe-area bounds, scrolling, selection and dismissal using local callbacks. Local visual qualification and two final connected cycles precede any uniquely qualified retained-data Redmi review APK. No OPPO, WhatsApp, production mutation, real external action, backend completion, integration, acceptance or ticket closure is authorized by this amendment.

## Shared collection dependency admission — 7 September 2026

Founder and Cursor authorize the primary Codex owner to admit exactly one immutable shared dependency after parent `7ef7711e119a4c4d7691423538a91ecc0499c2f2`. Cursor is paused; preserve the four unstaged navigation drafts recorded in `C:/GUARANTEED OUTCOME/MOOLSOCIAL-CURSOR-BUY-UAT-20260905/CURSOR-SHARED-CONTRACT-ADMISSION-PAUSE-20260907-V1.json`. Do not stage, format or modify them. This is an mvp_supporting dependency admission, not a product integration or consumer implementation.

| Dependency | Exact identity / responsibility |
|---|---|
| Import | `package:moolsocial/features/work/scan_and_pick_contract.dart` |
| Source commit | `6ea045b3243c5b06f5eeb28c9aa12670f8ff1156` |
| Git blob | `aad041323be2b987f28d00438fd98d96bc5b0ea2` |
| SHA-256 | `4F51CB811007F838DE517CDF49970ABCC8F6434B16B3BA78069B10AB8A904993` |
| Definition and sole writer | Codex `/root`; Cursor may import but not edit, duplicate or replace it |
| Examples and errors | `apps/mobile/lib/features/work/SCAN-AND-PICK-CONTRACT-V1.md` at the same Codex commit, read-only reference; not copied into this branch |
| Consumer 022-R5-A | Cursor: existing public Store page, purchase/payment, same paid order, order-specific scanner, inline recovery, status refresh, exact return and Redmi evidence |
| Retailer | Codex: existing central card; preserve biker handover |
| Pending dependencies | Authenticated authoritative transport, purchaser/order/store/SKU/payment/readiness/revision validation, short-lived challenge renewal, replay and durable idempotent reconciliation, public-store/auth return and integrated consumer-retailer acceptance |

The paid order and customer scanner entry have no collection-time cutoff. The short-lived security QR can renew without expiring the purchase. Server-confirmed Matched permits the retailer to physically hand over and confirm Hand Over once; only authoritative Collected completes the order. No merchant-only, verbal-code, local-success, notification or legacy direct-completion bypass. No WhatsApp testing, backend activation, production payment or device action in this admission.

The single admission changes only this manifest, its scope hash, the existing coordination policy/checker and the exact Dart blob. Add the blob only to the primary claim (10 to11); Cursor remains42 and the registry remains4502 at its existing SHA. Preserve earlier admission history through the exact parent. The current single-use allowance may leave only the four hash-bound drafts unstaged while exactly these five owners are committed with subject `ui(buy-redmi-fixes-v1-20260905): admit immutable Scan and Pick contract`. Afterward freeze those five owners; normal fully-staged feature commits and clean handoff rules resume. Reject an altered blob, another owner/claim, changed scope, different parent/identity, staged draft or reuse. No lane/root/schema expansion or new gate file.

Admission checks prove blob identity, ownership, preserved drafts and gate behavior only. They do not qualify unexecuted navigation tests, consumer UI, Store UI, backend enforcement, physical scanning or the integrated transaction. Resume Cursor only after the admission commit is pushed, remote-equal and its post-commit implementation gate passes with the same four drafts unchanged.
