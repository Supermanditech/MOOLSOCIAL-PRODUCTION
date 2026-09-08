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


## Founder-authorized Accessibility dependency implementation — 8 September 2026

The founder explicitly directs: "start implementing any external or dependency you can read codex latest git work or local", referring to the pending collection wiring/persistence, global Accessibility, Work copy corrections and fresh build admission. This authorizes resolving their necessary ownership coordination; it does not activate backend services or real transactions. Select existing enhancement A11Y-001 first, without registering a duplicate ticket. The smallest mvp_required outcome is one working Accessibility entry in the existing Profile > Privacy & preferences > App preferences page, following device text/motion settings, preserving exact Back/return, and repairing the already recorded enlarged-text Security hero title. No new screen, route, preference store, permission, dependency package, collection transport or backend owner is needed for this slice.

Start from clean, pushed, exact remote-equal parent a201f8ed4e8ad6abc58e4f925791fa4db501317b. The other Codex worktree is read-only: its committed/remote tip a62c24b6dd3fb37c5c2e7ed98307a777dceba316 has seven preserved dirty records outside these exact dependency owners. Its Profile preferences, Security and preferences test files are byte-identical to Cursor. Its committed MainActivity has unrelated later changes; preserve both native implementations and add only the bounded accessibility channel in this branch. Do not copy that entire native file or change the other worktree/claim.

One coordination-only admission with this exact parent and subject `ui(buy-redmi-fixes-v1-20260905): admit global accessibility dependency` changes exactly the existing four owners: this manifest, its local scope manifest hash, coordination policy and coordination checker. Preserve all earlier admission blobs and history through this parent, especially the immutable shared ScanPick contract. Registry stays4502 with its existing SHA. Add exactly these three existing Flutter owners to Cursor (42 to45):

- apps/mobile/lib/ui_v2/profile/global_privacy_preferences_v2.dart
- apps/mobile/lib/ui_v2/profile/global_security_v2.dart
- apps/mobile/test/ui_v2/profile/global_privacy_preferences_v2_test.dart

Add only apps/mobile/android/app/src/main/kotlin/com/moolsocial/app/MainActivity.kt to the primary claim (11 to12), exclusively for a bounded `com.moolsocial.app/accessibility` channel that opens Android Accessibility settings on an explicit user tap, returns success/failure, and rejects unknown methods. Authentication, invoice, location, native configuration and every other byte outside the new marked registration block remain unchanged. Cursor gains no Android, authentication, router or backend claim. Primary and Cursor work in this isolated checkout serially with no concurrent mutation/check; there is no branch merge or broader shared-source import.

This exact exception supersedes historical blanket shared/native exclusions only for these four named owners and A11Y-001. All other exclusions and execution flags remain unchanged. The admission contains no runtime/test/results change and is frozen after sealing; runtime follows in a separate fully staged atomic implementation plus RESULTS. Validate positive and rejected extra/missing/replaced owner, altered manifest/scope, wrong ancestry/history, unexpected dirty/committed owner, replay and native-boundary cases on PowerShell5.1 and7. Keep old protections fail-closed; this admission does not by itself admit an APK source or change native accepted baselines.

Implementation validation: actual entry tap; correct native method/action; duplicate-tap suppression; successful return, unavailable platform, launch failure/exception and retry on the same page; current device settings reflected after resume; truthful follow-device persistence; light/social tones at normal/200% text, narrow portrait/short landscape and real insets; full Security title and exact Back. Reuse existing profile tests and Buy integration regressions, capture actual Flutter visuals, and run two affected regressions plus applicable native compile/source checks before a successor gated Redmi candidate. A11Y remains open until its actual Redmi action and acceptance; no backend, OPPO, WhatsApp, contacts/messages, real payment/order, shutdown or ticket closure is authorised here.


## Founder-authorized local verification and Work copy dependencies — 8 September 2026

The founder's explicit instruction to implement pending external/shared dependencies and continue local testing before Redmi remains authority. Accessibility implementation38fa1201488ae943487b58d4afe5d851f8b9fc37 is clean, pushed and remote-equal. Its29 Preferences tests,6 Buy return tests and40 reviewed Flutter frames pass, with clean changed-Dart analysis. The widened profile run reports57 passes and2 failures in unchanged Help/Security helpers that omit the production theme; native compile planning is blocked by stale tracked plugin paths; the old approved-native projection rejects the new, byte-bound Accessibility block. These retained failures are dependencies to repair, not waivers. Seven Work copy violations were already confirmed; their exact replacement strings are read-only from Codex c065dc28ae8c3b74cb9b288eddaf99f70f7b6fb4, remote-equal and clean for these owners. Do not copy its full Store implementation or change that worktree.

This mvp_supporting minimum completes credible local verification for the pending Redmi candidate. A single coordination-only admission with exact parent38fa1201488ae943487b58d4afe5d851f8b9fc37 and subject `ui(buy-redmi-fixes-v1-20260905): admit local verification dependencies` changes only the existing policy, this manifest, its scope manifest hash and coordination checker. Preserve all historical freezes through that parent, registry4502 and the immutable ScanPick contract. Add exactly four existing owners to Cursor (45 to49):

- apps/mobile/test/ui_v2/profile/global_help_support_v2_test.dart
- apps/mobile/test/ui_v2/profile/global_security_v2_test.dart
- apps/mobile/lib/features/work/screens/work_onboarding_screens.dart
- apps/mobile/lib/features/work/screens/work_workspace_dashboard_screen.dart

Add exactly two existing owners to primary (12 to14): apps/mobile/.flutter-plugins-dependencies and scripts/check-approved-ui-locks.ps1. No runtime/test/results owner belongs in this admission; freeze its four coordination owners after sealing. This exact dependency exception supersedes prior blanket exclusions only for these six named owners and the work below. Cursor gains no authentication, Android, router, dependency-package or backend ownership. No new screen, route, setting, package, reference, baseline, registry, APK authority or backend activation.

The two test helpers must use the app's actual MoolTheme while preserving all existing compact, route, security and error assertions. Work runtime changes are restricted to exactly seven copy substitutions recorded in the preimage binding: three onboarding hints and four dashboard strings. Onboarding raw SHA BB6E832A9B1BB032BF9B49B4D603A35A9FDE5B1BF08D7D39CCE86E96F3E354EC may become only08F7006B371E1939E3B525CC375427C57C7A489C2F792AA4FD20CD8B86E85709; dashboard C30C896CAA9A2560091B000B6D4859C1DE27971332BC526F5A4C930BD4E89C92 may become only971518A7D413D6D6DB7148678BB33E5896E5E4BF9690326CE82FD8480EC31742. All other Work behaviour and bytes remain unchanged.

Plugin metadata may change only date_created and the existing Android/iOS youtube_embedded_player_private_dev paths to the current worktree package directory. Preserve every plugin/dependency property and package/version; pubspec.yaml SHA FA2E683195273EE02DBFB315F88569FD2638C3FDE4E2B82B032EBC4BBE31DBB9 and pubspec.lock SHA4DE45D3DD966862B160102C682DA52A61213CE70B50BC90C82CC69F203E8589D remain fixed. Native source stays exactly4150F3FC71BFC1A924B7A5597C4CBFFC35D5AA42851CEFAB60B71F151FF471A1. The existing approved-UI checker may recognize only this exact branch/root/implementation ancestry and exact Accessibility block, remove that block for its existing accepted-native comparison, and reject every unrelated native change. All old/default paths, accepted reference hashes and original native protections remain intact.

Validate actual pending and committed coordination checks on PowerShell7 and5.1 with positive and injected wrong/missing/extra claim, altered scope/manifest, old-freeze mutation, wrong parent/subject, unexpected owner, replay and premature implementation cases. Then qualify the source/test/checker repair separately: all existing profile tests, Buy global routes, customer-copy gate, changed Dart analysis, exact native compile, exact lock positive/negative cases on both hosts and two final affected regression cycles. Preserve failures and their recovery. A fresh protected review-source admission and unique guarded APK are still required after shared collection wiring/persistence. Redmi testing, acceptance and closure remain pending; WhatsApp, contacts/messages, OPPO, real transactions and shutdown remain outside this work.

## Exact formatter binding correction — 8 September 2026

The existing founder-authorized local verification work includes fixing its actual formatting failure. Clean, pushed, remote-equal parent30228bd6d102123c92bf9a05a8b58180e64bc45c seals the six repairs and evidence. Two identical cycles pass59 profile plus6 Buy tests each; scoped analysis, customer copy, native compilation and exact native locks pass. The nonwriting Dart format check exposes one required line collapse after the shorter delivery description. Its preserved diagnostic changes only `detail:` and the following string onto one line; no behavior changes.

One additive coordination-only commit with that exact parent and subject `ui(buy-redmi-fixes-v1-20260905): admit exact dashboard formatting` changes only this manifest, its scope manifest hash and the existing coordination checker. Policy,49 Cursor/14 primary claims, registry4502, execution authority, accepted references and all earlier admission history remain unchanged. Freeze the previous four coordination owners through that parent, then freeze these three amended owners after the single admission. Require unchanged implementation at admission; reject wrong ancestry, parent, subject, extra owner, changed scope or policy, premature formatting and replay on both PowerShell hosts.

After sealing, the existing dashboard owner may transition only from971518A7D413D6D6DB7148678BB33E5896E5E4BF9690326CE82FD8480EC31742 to31CEDA835734EA697CDC570C4741968629825198F9008EED5E8E668BE19C1D9F. This supersedes only the earlier dashboard raw-copy hash restriction; the seven strings and all behavior stay fixed. Verify the actual formatter, analysis/copy checks and exact one-line diff. All other native/package/metadata protections remain. This admits no APK, integration, backend action, device acceptance or defect closure.


## Whole Buy regression and portable release prerequisites — 8 September 2026

The founder directs continued implementation of every registered Buy/Shop defect before the Redmi APK and explicitly defers cross-worktree/backend integration until Redmi qualification. This mvp_supporting dependency work restores complete functional verification and Windows build-tool compatibility. It introduces no customer journey, backend activation, deployment, real transaction or accepted-reference update. The full Buy/Profile run retained 1612 passes, 27 failures and 27 declared skips; all 27 failures are listed below. Correct stale fixtures only after checking current behavior, retain the original functional guarantees, and fix runtime defects in existing admitted Buy owners when demonstrated. Do not add skips or functional name exclusions.

From clean remote-equal parent99eeaabba897300320b2b19646d1efce44c57cba, admit exactly16 existing test owners to Cursor (49 to65) and30 portable-tool owners to primary (14 to44). The sole new file is the shared Windows PowerShell portable API helper. The tooling proposal replaces actual hash/relative-path APIs with equivalent portable functions and splits one negative-assertion literal without changing its value. Preserve the unchanged broad compatibility scan and every deployment guard; do not execute deployment scripts. Existing tool files may change only between the recorded preimage and proposed hashes. Tests retain meaningful identity, state, recovery, accessibility and geometry assertions.

The admission changes exactly the existing policy, manifest, scope manifest hash and coordination checker with subject `ui(buy-redmi-fixes-v1-20260905): admit full regression and portable tooling`. Freeze every earlier admission through this exact parent, preserve registry4502, all runtime/native/package pins and scope authority. Require preimages and no implementation during admission; reject changed claims, scope, manifest, ancestry, parent, subject, extra dirty/committed owners, replay and post-admission coordination changes. Freeze the four admission owners afterward. Apply the tool proposal only after admission and verify its20 cases on both PowerShell hosts, the actual broad compatibility gate and unchanged protection gates. Run all affected tests and two complete Buy/Profile cycles, explicitly account for declared skips, then fresh source/build admission and checksum-bound Redmi replay. No skipped defect closure, APK authority, backend integration, OPPO action, messages or shutdown is granted by this amendment.

Machine-bound exact owner/preimage data follows. The failed run and external portability proposal remain immutable evidence.
<!-- R669-DATA-BEGIN -->
{
  "parent": "99eeaabba897300320b2b19646d1efce44c57cba",
  "tests": [
    {
      "path": "apps/mobile/test/ui_v2/buy/buy_v2_bank_transfer_pending_test.dart",
      "beforeSha256": "EA1EDF6C02CDDB21B24B889234066B7AC430B4C62F4E63E0682E83A6099D3D48"
    },
    {
      "path": "apps/mobile/test/ui_v2/buy/buy_v2_bottom_rail_action_inventory_regression_test.dart",
      "beforeSha256": "94ECDA6B67E8560C30497D34391E37D4E59B6AA51E8AE1F644139198D0BB30D0"
    },
    {
      "path": "apps/mobile/test/ui_v2/buy/buy_v2_catalogue_copy_hierarchy_test.dart",
      "beforeSha256": "C040F77A2358AFCCEB0BF7A3E4D5429E5C546CFA7EFC80786E66BDAFE3B51E0B"
    },
    {
      "path": "apps/mobile/test/ui_v2/buy/buy_v2_filter_sheet_motion_test.dart",
      "beforeSha256": "D682B9F8BEB7272909D7B83E0D406F1C7BB45E9F03B21E24451A8EA96837A0C0"
    },
    {
      "path": "apps/mobile/test/ui_v2/buy/buy_v2_help_chat_unification_test.dart",
      "beforeSha256": "1E40E6FED2EA7606AC477599D7AEBBEF73FF96078084FDAE26DAB38758316E36"
    },
    {
      "path": "apps/mobile/test/ui_v2/buy/buy_v2_info_sheets_motion_test.dart",
      "beforeSha256": "89A4FD4B9DE6B4435578E86D10A7234B127757986D625CAC2941D51DD25DA55F"
    },
    {
      "path": "apps/mobile/test/ui_v2/buy/buy_v2_marketplace_trust_test.dart",
      "beforeSha256": "51A921E8D0C72C0213E97B6D687A457E5EC1C14A1B1EEEEAA6429D918201866F"
    },
    {
      "path": "apps/mobile/test/ui_v2/buy/buy_v2_payment_sheet_motion_test.dart",
      "beforeSha256": "59B8404E00C309EE070DB3F3CB5F4BFEC6596A52332B01819138A244B108366C"
    },
    {
      "path": "apps/mobile/test/ui_v2/buy/buy_v2_policy_snapshot_test.dart",
      "beforeSha256": "91126117FD6554A1F09CB50C7E422E95B28B46AC937B22F6554A00BF31887A6F"
    },
    {
      "path": "apps/mobile/test/ui_v2/buy/buy_v2_product_actions_test.dart",
      "beforeSha256": "09572575A0D5D33A2832EF0D502302C6D0B4660C9154B7C913717B6270D100C6"
    },
    {
      "path": "apps/mobile/test/ui_v2/buy/buy_v2_product_offer_decision_test.dart",
      "beforeSha256": "BFFBB8DBC80365FEAA3322443019AD984870334C7AF62A8829012A676B486C40"
    },
    {
      "path": "apps/mobile/test/ui_v2/buy/buy_v2_promotion_rail_state_test.dart",
      "beforeSha256": "B6B2899FA6BE6911EB1697F953441CABAA840F38629F22E6183F06C7CFB83B61"
    },
    {
      "path": "apps/mobile/test/ui_v2/buy/buy_v2_shop_chat_test.dart",
      "beforeSha256": "9E0A09C105C45D6F886BF1CE12EC912E6CA329A4B063FAEC821C0FAF0BC56A9C"
    },
    {
      "path": "apps/mobile/test/ui_v2/buy/buy_v2_shop_pharmacy_seller_continuity_test.dart",
      "beforeSha256": "3ED616F534028B60FC02D5539C7F8837645591DFB35ADC33A45F9DC7ED6534D9"
    },
    {
      "path": "apps/mobile/test/ui_v2/buy/buy_v2_shopping_intent_journey_test.dart",
      "beforeSha256": "114E93F13BA45555A40136FE189F6F87C5AA41CBD5BEEC22B3B53EA00F803318"
    },
    {
      "path": "apps/mobile/test/ui_v2/buy/buy_v2_wholesale_payment_attribution_test.dart",
      "beforeSha256": "7C19D5697BB4536F68B5F5F34C70E821B6588869927378A8476DD1123FED06B9"
    }
  ],
  "tools": [
    {
      "path": "scripts/check-buy-approved-reference.ps1",
      "beforeSha256": "788BAE1D74CD35A77E00BD00057C283D73BDF31F04D33965B4529ECA2A8C09C7",
      "proposedSha256": "CDED68BE067A8869DD71A7581E7D47FDD6E2B04A767D30033B8933A5560BDCCD",
      "calls": 2,
      "negativeAssertionLiteralOnly": false
    },
    {
      "path": "scripts/check-personal-android-navigation-device-matrix-c28d.ps1",
      "beforeSha256": "0CD8D25B1A8621AC2ADE9AEE6C8CBCD0034EBF6C7B58387A9F0CE62362D21FD9",
      "proposedSha256": "AEC08DDE8E33EF147F71D917517012905358052128902825FECACC3B6E39ED3C",
      "calls": 2,
      "negativeAssertionLiteralOnly": false
    },
    {
      "path": "scripts/check-personal-approved-navigation-device-matrix-c26h.ps1",
      "beforeSha256": "3AFC80961DAAE049D916FF9A9E79BAD8022C20FA6ECD8378325440CC55FBC684",
      "proposedSha256": "396E6680E210AD9D40D4B8EA6A12E653CD6EDB90B17910E2F30E3907B9356224",
      "calls": 2,
      "negativeAssertionLiteralOnly": false
    },
    {
      "path": "scripts/check-personal-social-dev-backend-deployment-c29u.ps1",
      "beforeSha256": "E499881208A670C16D53C740FD9D02BE1433F2AEEFE3D6EFFFBCE3E6722F0712",
      "proposedSha256": "ED66CA51A95D69DE5A8381A19A393B95FF37EE55FCBB7906551B1682E7350043",
      "calls": 2,
      "negativeAssertionLiteralOnly": false
    },
    {
      "path": "scripts/check-personal-social-dev-content-redeploy-c30k-fix1.ps1",
      "beforeSha256": "7E6EE43123B13C53EF54917CBE0C039318CEB9A7C21659E5A1276FB418D23935",
      "proposedSha256": "93B8B9240AB4CEE82E542CA21088BD12A66F0A4B022C0AA3F70336376EBFBBC9",
      "calls": 1,
      "negativeAssertionLiteralOnly": false
    },
    {
      "path": "scripts/check-personal-social-youtube-quota-purpose-catalogue-refresh-c29r.ps1",
      "beforeSha256": "2F4323C99FF110C9D4A2D6D0A0C9D7DC40E7C5DDDB3C615A49651E3BF6D1DFA6",
      "proposedSha256": "FB830641E6DD4A7BEC7DDD093DF66CA72B930531A6CBFE4F10174BDCD307185D",
      "calls": 1,
      "negativeAssertionLiteralOnly": false
    },
    {
      "path": "scripts/check-personal-subaction-clear-glass-host-qualification-c17e.ps1",
      "beforeSha256": "DF941283C09553D8A780EAD6468D90AC7BCD8C5214EBBE71CDF6A92CE26828D0",
      "proposedSha256": "E1D4A3C562AE7F05C7AD781803BCD52A5F834F094B0657FC5B43B7CCAD57E56B",
      "calls": 2,
      "negativeAssertionLiteralOnly": false
    },
    {
      "path": "scripts/check-release-lifecycle-transition-c34l.ps1",
      "beforeSha256": "D5D289094E299CD96754097D2A432BEE67FC1AB579D98CEFA3A2790E36C50D52",
      "proposedSha256": "341B73102E135D19D250EF83CF8833D6657CA1AF3820D2178299F1884CCE604A",
      "calls": 0,
      "negativeAssertionLiteralOnly": true
    },
    {
      "path": "scripts/check-youtube-private-dev-content.ps1",
      "beforeSha256": "5E220BC6214F0FA5A65BE48A64EA0FDDA7A936A0F4F18C5D7D0B0F167DB3A8D7",
      "proposedSha256": "2255C05613661C0D90BA4E6D4FAAD7A1D2185C81C71F880C47B6D6B54269C644",
      "calls": 2,
      "negativeAssertionLiteralOnly": false
    },
    {
      "path": "scripts/deploy-c30t-dev-provider-only.ps1",
      "beforeSha256": "29E726A49844F8E2433881F5B50D07C9860C46391FF2FFC642952CE94EF8FB14",
      "proposedSha256": "51B905D775071CEFECAF83AA3A95FEAE79538B463FA696837E6BF770A9864972",
      "calls": 2,
      "negativeAssertionLiteralOnly": false
    },
    {
      "path": "scripts/invoke-flutter-with-clean-support.ps1",
      "beforeSha256": "A0F999AA613D8DC475E35AC71D0E9A55E5808DB7C00E5942BDD53D060341A5F4",
      "proposedSha256": "FB7B5AE3C58E60D035D8D2D44516A5B6CA3FB17595ED6AF2301BE20B2DDE3B0F",
      "calls": 2,
      "negativeAssertionLiteralOnly": false
    },
    {
      "path": "scripts/new-c30t-provider-hosting-source-manifest.ps1",
      "beforeSha256": "FB2B4132DE15EFDF28C4B8388304A07F0A2A7DC294E644AD34091375C5A605F6",
      "proposedSha256": "766713327925C2013821038033CCAC318EAD015A2FED7877C4A8A7651ED40BAA",
      "calls": 4,
      "negativeAssertionLiteralOnly": false
    },
    {
      "path": "scripts/new-c30u-backend-deployment-manifest.ps1",
      "beforeSha256": "F8363DE2C1D298EDE4DA480B67FFF0A33412FE0C5B6EF7B0437504E6CFAAEEFB",
      "proposedSha256": "5CEDE4C5AF672544B15C82A4FC9F4E9839D13847AE090F7EE33DE8F908BFA841",
      "calls": 2,
      "negativeAssertionLiteralOnly": false
    },
    {
      "path": "scripts/new-c30u-source-manifest.ps1",
      "beforeSha256": "D3696ECF50BE67787ED0237C616FB33E481B5F41D083C748061ED8A10CD61E37",
      "proposedSha256": "BCDAC9779630610C5465E5174A3D986B00997AB943509777F7C984577BD58FB9",
      "calls": 4,
      "negativeAssertionLiteralOnly": false
    },
    {
      "path": "scripts/new-c30v-source-manifest.ps1",
      "beforeSha256": "12DE5D266EE789FED88E7BB203DCC233267C9F0E26BC4E93A87A5525977314F9",
      "proposedSha256": "2A94D1D404996C9A76B09C81137B841B1C02341CE6E8E1F6FE1E1241873DBED9",
      "calls": 4,
      "negativeAssertionLiteralOnly": false
    },
    {
      "path": "scripts/qualify-personal-android-navigation-c28c.ps1",
      "beforeSha256": "5E797FAA8EE6C43A3BAF416D8DC7B8C6C7CBD62BB407BA016DAB8D79209B1E4D",
      "proposedSha256": "9CCBE1BCE2D5566EBE55451E8D6935569F83FEF1EA1F88E8996EAF2D1CA0879C",
      "calls": 2,
      "negativeAssertionLiteralOnly": false
    },
    {
      "path": "scripts/qualify-personal-approved-navigation-c26g.ps1",
      "beforeSha256": "7C2D2EC940361CB857BCCCA9F1F7C7C774ECF6956000510BC4BC047B6FB7F983",
      "proposedSha256": "8341BE6DABE28A9BEBF4CA7E691B81892128ED64AA36C6B8377E1204E49CE947",
      "calls": 2,
      "negativeAssertionLiteralOnly": false
    },
    {
      "path": "scripts/qualify-personal-capsule-system-host-c22g.ps1",
      "beforeSha256": "F9F4050CAA53C0A8C00FA19473C17D935A241A7AA514CF76CA31D4BBEDC159D7",
      "proposedSha256": "C4D7597AB2AB15CEC7F5678900E69E82A46B2F04B6F024F59748F740CEFDAC66",
      "calls": 2,
      "negativeAssertionLiteralOnly": false
    },
    {
      "path": "scripts/qualify-personal-domain-navigation-c25g.ps1",
      "beforeSha256": "09AEAE48EC383C5713CCF3E416162FB1359A85739ACC7AC5D7898AF130A7DC17",
      "proposedSha256": "E7F846DDAFA377E16A4F7DCF5E8E7020C0F1C487FDB5876B57F3D2B42AAC6B03",
      "calls": 2,
      "negativeAssertionLiteralOnly": false
    },
    {
      "path": "scripts/qualify-personal-global-subaction-host-c20g.ps1",
      "beforeSha256": "6538D13F369C8E3B58BC7777D85DF4CBC2883512AD8B1A8289883B1A2824E031",
      "proposedSha256": "EDB6B55A0707083689A1458F178A75CDA2B59981E1B913367C6B5648C994261F",
      "calls": 2,
      "negativeAssertionLiteralOnly": false
    },
    {
      "path": "scripts/qualify-personal-global-subaction-optical-host-c21g.ps1",
      "beforeSha256": "EBE848F539F62596E77A8CCE871B2BFDA39E02F90457DC185D2BD03BA7743DD7",
      "proposedSha256": "1B5FD6B1846748822D107D8B2AD2782583F52C461A7F619305C91D3F170E0D9B",
      "calls": 2,
      "negativeAssertionLiteralOnly": false
    },
    {
      "path": "scripts/qualify-personal-mool-home-action-hub-c23g.ps1",
      "beforeSha256": "EDBFC029EBD717EB7B8BB924830C48B79AD688C2A76554858E93DFAEC03919E6",
      "proposedSha256": "E653A18863A9CB673D0418F7F9B1042888E6F4082460A7B8D0DF872BFC7E508E",
      "calls": 2,
      "negativeAssertionLiteralOnly": false
    },
    {
      "path": "scripts/qualify-personal-service-home-c24h.ps1",
      "beforeSha256": "99473E8CD9F2A6F76A2F24FFC762FF8F6EE9E47795F94CDB4D073DCD9530B75F",
      "proposedSha256": "0AE5F0D66CEABAFCD146434312224EF3B4E33982D019F95BC8BB00E3CE65DD0C",
      "calls": 2,
      "negativeAssertionLiteralOnly": false
    },
    {
      "path": "scripts/qualify-personal-social-creator-ergonomics-global-edge-consistency-c29n.ps1",
      "beforeSha256": "A4B82832FE19513C1FD8F57400B165AAF154E1B54923CE96CCA33802E8020F6C",
      "proposedSha256": "BF286E05531AB7D7FF0C225E27864C641BB80B0B55F5CCDB1E781A9538F35C53",
      "calls": 1,
      "negativeAssertionLiteralOnly": false
    },
    {
      "path": "scripts/qualify-personal-social-youtube-creator-connection-private-short-upload-c29l.ps1",
      "beforeSha256": "B7D5FF3B85F045244AD42B31F118CF49EA0297AC9F5AC71E55BE6C9A83426E3D",
      "proposedSha256": "4D3EFF7553647079B220399EF7DE53B553B6C8A6AA4EC73A337A6F851935C656",
      "calls": 1,
      "negativeAssertionLiteralOnly": false
    },
    {
      "path": "scripts/qualify-personal-uniform-navigation-c27e.ps1",
      "beforeSha256": "A71A6355E73C599998C074624611C9ACAC0407DD08E493C1EF2991280F9745B0",
      "proposedSha256": "ABE9D0883C349EC6397E62614CFD7675952ADE2D191F0AF66E7B64C9690E6A77",
      "calls": 2,
      "negativeAssertionLiteralOnly": false
    },
    {
      "path": "scripts/qualify-play-internal-firebase-startup-c30s.ps1",
      "beforeSha256": "F4B2755DEDA49221F44684B52B47C0994AA0DBD5B385C3B32B1F338B58FE383D",
      "proposedSha256": "016112614F81081C46735011A3512BE750D43C1CF6506D43AA796AE847A49B2D",
      "calls": 2,
      "negativeAssertionLiteralOnly": false
    },
    {
      "path": "scripts/qualify-play-internal-live-read-recovery-c30t.ps1",
      "beforeSha256": "1BDFD0DE0A0DDF2800C6393DF21B64C7F8C86538AECEB1670D743F04195A8778",
      "proposedSha256": "5FD66B4003CA9177BCEC9928B9D35263F61A9F4D368E3746DEFABB3768AD2789",
      "calls": 2,
      "negativeAssertionLiteralOnly": false
    },
    {
      "path": "scripts/test-social-runtime-deployment-execution-r60-92.ps1",
      "beforeSha256": "AE1137C8297D62AE93C8ED58382A2899547BC8D4700927BAB852A7E4C63201AD",
      "proposedSha256": "D7AB74E8375C8CFFC326423E3645EC018BCBB573144858408F9D7D68B5D6F65C",
      "calls": 2,
      "negativeAssertionLiteralOnly": false
    },
    {
      "path": "scripts/windows-powershell-portable-api.ps1",
      "beforeSha256": null,
      "proposedSha256": "1DF7072524D0F9E6F3CB24447F6884252962D4223F6102597CB04285E8C7BEFC",
      "calls": 0,
      "negativeAssertionLiteralOnly": false
    }
  ],
  "failures": [
    {
      "path": "apps/mobile/test/ui_v2/buy/buy_v2_bank_transfer_pending_test.dart",
      "test": "Bank transfer shows exact instructions then remains pending without a duplicate order"
    },
    {
      "path": "apps/mobile/test/ui_v2/buy/buy_v2_bank_transfer_pending_test.dart",
      "test": "pending Bank transfer survives customer-state restoration"
    },
    {
      "path": "apps/mobile/test/ui_v2/buy/buy_v2_bottom_rail_action_inventory_regression_test.dart",
      "test": "Offers and GST overlay do not remove the established rail"
    },
    {
      "path": "apps/mobile/test/ui_v2/buy/buy_v2_catalogue_copy_hierarchy_test.dart",
      "test": "promotion hierarchy wraps primary copy at compact large text"
    },
    {
      "path": "apps/mobile/test/ui_v2/buy/buy_v2_filter_sheet_motion_test.dart",
      "test": "real catalogue tools flow reaches the R56.6 filter sheet"
    },
    {
      "path": "apps/mobile/test/ui_v2/buy/buy_v2_filter_sheet_motion_test.dart",
      "test": "unified tool action runs only after the reverse route"
    },
    {
      "path": "apps/mobile/test/ui_v2/buy/buy_v2_help_chat_unification_test.dart",
      "test": "Checkout help opens shared Chat without entering the retired Assist view"
    },
    {
      "path": "apps/mobile/test/ui_v2/buy/buy_v2_info_sheets_motion_test.dart",
      "test": "household arrival/reverse is finite and Back never mutates"
    },
    {
      "path": "apps/mobile/test/ui_v2/buy/buy_v2_info_sheets_motion_test.dart",
      "test": "household actions apply once from the explicit modal result"
    },
    {
      "path": "apps/mobile/test/ui_v2/buy/buy_v2_info_sheets_motion_test.dart",
      "test": "Saved sheet holds invocation destination and animates real owner"
    },
    {
      "path": "apps/mobile/test/ui_v2/buy/buy_v2_info_sheets_motion_test.dart",
      "test": "compact 140% sheets keep actions, semantics and focus safe"
    },
    {
      "path": "apps/mobile/test/ui_v2/buy/buy_v2_marketplace_trust_test.dart",
      "test": "verified ratings and seller facts remain product-specific"
    },
    {
      "path": "apps/mobile/test/ui_v2/buy/buy_v2_payment_sheet_motion_test.dart",
      "test": "PhonePe collection moves action required to pending and confirmation"
    },
    {
      "path": "apps/mobile/test/ui_v2/buy/buy_v2_policy_snapshot_test.dart",
      "test": "Checkout and Order items retain the published product policy"
    },
    {
      "path": "apps/mobile/test/ui_v2/buy/buy_v2_product_actions_test.dart",
      "test": "manufacturer Chat action stays readable and fails safely at 140 percent"
    },
    {
      "path": "apps/mobile/test/ui_v2/buy/buy_v2_product_actions_test.dart",
      "test": "Shop seller products open and return to the exact product"
    },
    {
      "path": "apps/mobile/test/ui_v2/buy/buy_v2_product_offer_decision_test.dart",
      "test": "ready Shop offer shows the complete decision before Add"
    },
    {
      "path": "apps/mobile/test/ui_v2/buy/buy_v2_product_offer_decision_test.dart",
      "test": "Retry refreshes a stale offer before Cart becomes available"
    },
    {
      "path": "apps/mobile/test/ui_v2/buy/buy_v2_product_offer_decision_test.dart",
      "test": "product offer decision stays usable at 320 and 140 percent"
    },
    {
      "path": "apps/mobile/test/ui_v2/buy/buy_v2_promotion_rail_state_test.dart",
      "test": "both promotion intents fit without horizontal clipping"
    },
    {
      "path": "apps/mobile/test/ui_v2/buy/buy_v2_shopping_intent_journey_test.dart",
      "test": "monthly basket intent reaches curated products and persists through Checkout"
    },
    {
      "path": "apps/mobile/test/ui_v2/buy/buy_v2_shop_chat_test.dart",
      "test": "product supplier Chat keeps exact context above the compact keyboard"
    },
    {
      "path": "apps/mobile/test/ui_v2/buy/buy_v2_shop_pharmacy_seller_continuity_test.dart",
      "test": "Shop exposes automatic fulfilment without seller continuation"
    },
    {
      "path": "apps/mobile/test/ui_v2/buy/buy_v2_shop_pharmacy_seller_continuity_test.dart",
      "test": "Medicine pharmacy action keeps prescription and safety facts"
    },
    {
      "path": "apps/mobile/test/ui_v2/buy/buy_v2_wholesale_payment_attribution_test.dart",
      "test": "active Wholesale order owns explicit actors and payment schedule"
    },
    {
      "path": "apps/mobile/test/ui_v2/buy/buy_v2_wholesale_payment_attribution_test.dart",
      "test": "Wholesale invoice exposes buyer, supplier, payment status and due date at 140 percent"
    },
    {
      "path": "apps/mobile/test/ui_v2/buy/buy_v2_wholesale_payment_attribution_test.dart",
      "test": "Wholesale tracking identifies both buyer and supplier roles"
    }
  ]
}
<!-- R669-DATA-END -->
