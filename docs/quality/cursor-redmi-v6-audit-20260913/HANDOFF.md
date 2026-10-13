# Current Cursor catalogue handoff â€” 16 September 2026

This section supersedes older checkpoint statuses below. Founder-directed task: preserve Cursor work and prepare the Store-owner-to-public-catalogue handoff. Runtime implementation is paused. No new APK, backend change or device test was made for this handoff. Read this section, PUBLIC-DATA.csv and the current end of DEFECTS.md before catalogue implementation.

## Exact branches, baselines and preserved work

- Working branch: `work/cursor-ui/redmi-v6-audit-20260913`; worktree `C:/GUARANTEED OUTCOME/MOOLSOCIAL-WORKTREE-CURSOR-redmi-v6-audit-20260913`.
- Previous Cursor integrated baseline: `da4d266f97b4081f55bd98f1e9522f25bc8ee05f`. Latest separately installed integration reported in the request: `21977bff27cf22bfadb50f592a635355bb80574e`, source `54eae4970959d39cb978cd01082be828625721f9`. Their common ancestor with this Cursor branch is `11cdabb727e820fcf888089a58b6699d9addfda7`. These are different branch snapshots; no integration or history rewrite was performed.
- Last locally qualified application source: `f0fc06a92bb43627ec4ca952e8996a888ec96ac2`; build seal `e450af636f61e86abbcbb9fd3acb1fe34d2696dc`; device-evidence closure `067b26d1c66ac9511d026539470103baaea194fc`; C04 reopening `e5d39769e260c1a6691ea7808642308472261a97`.
- Current unqualified catalogue drafts preserved on this branch at `8ecf24a9a7c14a492f603c019c0d40ef805b8aab`. This commit also registers C06/C07 and admits exactly the preserved catalogue bytes through the existing source pin. It does not qualify these drafts or waive APK/test gates. The runtime file matches the prior archive after CRLF/LF normalization (LF SHA256 0770772C953D85C1DB861EF2444F492063AC39C092916BAEF8CC6E78AD1A659A); its line-ending bytes differ from that snapshot. The prior archive is `72f5d36a45525ee36740a1e7214d0cc88a8a0f2a`, branch `archive/preservation-20260916-cursor-catalogue`.
- Earlier audited branch histories are already remotely preserved under `archive/preservation-20260916-codex-history` at `68b2316cea213c26ebc6bb9b095c8fd1f415c596` per the supplied request. They were not re-audited or altered. This handoff separately records all 269 first-parent Cursor commits since the common ancestor, including the V6 integration; full SHA/subject ledger is archived as `CURSOR-COMMIT-LEDGER.json`.
- Additional raw evidence archive: `archive/preservation-20260916-cursor-redmi-evidence`. First commit `a56c1ed94d105a68ae68770231e67c5a8e74f776` preserves 2,647 SKU-era files (390,915,861 bytes) under `docs/quality/preservation-20260916/cursor-redmi-evidence/`, plus its manifest. One tool font input is hash-inventoried rather than copied. V6 archive details and final remote receipt are recorded in the preservation appendix below.

## Ticket reconciliation and qualification limits

Original 22 RV6 defects and sole child D005-C01 retain their recorded scoped device closures. This is not full-app production acceptance. Each row resolves exact Git objects; detailed failed attempts, fixture limitations, narrow founder approvals and device captures remain in DEFECTS.md/UAT.md/EVIDENCE.csv and the evidence archive.

| Original | Implementation or final correction | Device/evidence commit | Current disposition |
|---|---|---|---|
| RV6-D001 | `d532b9dea97a52473a5a95e090a9831fd9635696` | `acb50158692686326193fdd9a17cc011c93ab3b6` | Retained scoped device closure |
| RV6-D002 | `55877c20437bdc34c1a90de19904381e94014cde` | `8686895bbc10dedd25da73726da7eab9caba2d39` | Retained scoped device closure |
| RV6-D003 | `e01ff726fd7b92ecb8c3fd6928cc9f248b9f6eaa` | `2d8adbeba9071b4d628de090590606b1994ad44b` | Retained scoped device closure |
| RV6-D004 | `2967bf188ffe6587a9f3e6409584ce3686504f60` | `2ca408bd9bac0b87ad4492e4fc2fce9e3e78c17d` | Retained scoped device closure |
| RV6-D005 | `dce65c05ab54b39751211a608c923c00226e4a26` | `448d4a2c7c10ee195e711e49aa4cc69a593ff37b` | Retained scoped device closure |
| RV6-D006 | `ed0233761e825e22a4d6e14c7d0f0e0073f9ea25` | `4a13f2f53824df91183003fdf332f80f8a32d42f` | Retained scoped device closure |
| RV6-D007 | `e604579b1f102573766bcaee8bcbf772f9cf96bd` | `d4225c31a5f3ff947fae35dc449423f501ca3605` | Retained scoped device closure |
| RV6-D008 | `0fe77e604fc4787a3b1584a3c0e3e92bff1e53e5` | `01cea97bd0431a18490d4da722c151ebbdd963a1` | Retained scoped device closure |
| RV6-D009 | `e29194eb14d0d90ebf37eff329705e8ee4ec2381` | `b7012e92f583fcf48ae428bc89f208b665537337` | Retained scoped device closure |
| RV6-D010 | `6fcb36cbd8e9ae1b42ee7f97c31230633b50f0f1` | `b7012e92f583fcf48ae428bc89f208b665537337` | Retained scoped device closure |
| RV6-D011 | `b46c582bc747c15576f8349b0c2fd144d452f02b` | `8ee766845c473160f101f2de209776860fb45181` | Retained scoped device closure |
| RV6-D012 | `4194ea5985bc95ddd228f25011ccf198dda38926` | `2be0968529f43e41cf6a95f07b8b7e46f4d0035e` | Retained scoped device closure |
| RV6-D013 | `4fccb654d602319e4b7352c5160e93c2bbf4e485` | `2be0968529f43e41cf6a95f07b8b7e46f4d0035e` | Retained scoped device closure |
| RV6-D014 | `41412f56a4af4d75e2976dc04843dd293ae4869d` | `9d775c481b749833127039b2ac6cf0fd71d57a51` | Retained scoped device closure |
| RV6-D015 | `0c10682b9c5e6955e5cf845de8897090b95f60d4` | `2be0968529f43e41cf6a95f07b8b7e46f4d0035e` | Retained scoped device closure |
| RV6-D016 | `ac5a95e5f8fa410ca4e5d0e8c41ca5de7bd271eb` | `8bd95d77150e9c2ff69761648e1dbbd8f0879f3e` | Retained scoped device closure |
| RV6-D017 | `99f74b80e37850003f7fdd37db81e71387fbc9ca` | `fb185f98c82a5ddf0d6c392bf7bd9ce7ad4081cc` | Retained scoped device closure |
| RV6-D018 | `04afab670c14e5cc425269f6753a3410e0b82548` | `859056fcae9b88d7199aae4d330871ea64865f91` | Retained scoped device closure |
| RV6-D019 | `70b117b966a58ca4a551edb31742e175c2723dde` | `84a7ab62311c049e10339edf715db05e8ee3bd49` | Retained scoped device closure |
| RV6-D020 | `9a81541e866975c15c4044f8a5d68906e45dd638` | `cde06820f2e55366839e721f0609d7bb76402207` | Retained scoped device closure |
| RV6-D021 | `7e811a753a9896947f514a209f50138d21ea9544` | `aaeb75fc9187a72f8c16f29c29b4f70732bf242b` | Retained scoped device closure |
| RV6-D022 | `4eb257d146fa656b63d7e0fe003cc8898ee8cd09` | `2949b9071f016c4bce6826ff8ab2720b28b3a7d3` | Retained scoped device closure |

D005's language availability disclosure and C01 persistence are distinct: C01 implementation `3c30ba11`, prebuild `f1500cb2`, device `448d4a2c`; the historical commit-label exception is recorded by `3f4d1cf9`. D003 also retains `cd92728c`; D007 `9d73a543`; D014 includes `da26e9ff` and `4221158f` before final `41412f56`. D019 is evidence reconciliation rather than a new runtime fix. No historical failure or blocked trial is erased by a later pass.

SKU work has **14 records: 11 retained scoped closures and 3 open**. Initial implementation sequence includes `253cbe16` through `d6d9890f`; navigation `64ca4d75`; final control-row/media correction `f0fc06a9`; scoped evidence `067b26d1`. Full commit ledger retains intervening atomic fixes.

| Records | Current result and evidence |
|---|---|
| SKU-M01, M02, M03, M04, M05 | Retained scoped closures at r66.28 checkpoint; M04 Orders and applicable Cart/Recent checks explicitly reuse unchanged r66.26 evidence. Media overlap correction belongs to M01. |
| SKU-M01-C01, C02 | Retained scoped closures: price-only yellow emphasis; three normal-scale columns with adaptive enlarged text. |
| SKU-M05-C01, C02, C03, C05 | Retained scoped closures: page-state continuity; vertical discovery; variable provider metadata local qualification; both visible pagination/control rows removed. C01's old visible numeric pagination requirement is superseded by C05. |
| SKU-M05-C04 | OPEN/reopened: entire three-column grid must follow horizontal drag across Shop, Wholesale/Bulk, Offers and Store/Supplier. Current device changes contents after release without moving the whole grid. Draft untested. Vertical scrolling in both directions remains founder-approved. |
| SKU-M05-C06 | OPEN: duplicate product/store loading bars while typing mil/milk. Partial draft removes duplicate bar; no qualification. Preserve the founder-approved delivery shortcut beside Search while keyboard is open. |
| SKU-M05-C07 | OPEN: founder reports rotation from Shop unexpectedly opening Mool menu without a tap. Captured destination only; trigger/root cause not independently reproduced. No implementation. |

`R668-AUDIT-MEDIA-002` remains an external owner-publication dependency, OPEN. Existing decoded-photo local fixtures and device illustration checks do not establish live supplier upload/publication or device video qualification. Earlier 87-item audit/history remains preserved, not reclosed by this handoff.

Installed Cursor Review remains r66.28, package `com.moolsocial.app.cursorreview`, version code `2026091601`, Redmi `TG8HCYTGGQT885OF`. APK SHA256 `B3172EFB64135D606CD249F751617FE21AB065E50996FE459AEEF991CA7946A8`. No data clear, reinstall or new runtime verification in this handoff.

Historical source qualification: `current-source-qualification-04.json`, SHA256 `C8F598EE3007D1486F66433731257C90B74A1B9FC99281DFC3470EB18B0E30B6`; 3,044 source hashes, analysis no issues, two combined runs each 2,454 passes, 27 inherited skips and zero failures. Ten protected exclusions are not passes. These results apply to f0fc06a9, not 8ecf24a9 WIP. Historical device report `r66.28-final-qualification.json`, SHA256 `D8A4A26B26F3165048C6D1AEAA9763A2601324F07C8B8DCB03F4E03EF4296873`, is superseded only for C04 by the later drag evidence. No redundant regression was run for this documentation/preservation task.

## Field-by-field contract and owner-publication trace

`PUBLIC-DATA.csv` contains 271 rows: all 71 historical rows retained unchanged in their original columns, plus CAT-001 through CAT-200. The 200 comprise all 185 declared final fields of 17 enumerated public product/store/media/facts/trust/offer/comparison classes, plus 15 explicit Store/private-field gaps. Source paths/lines/commits, consumers, provider, editor, save/publish behavior, actual validation, visibility, authority and required update/unpublish behavior are recorded per field. Contract metadata is distinguished from rendered labels; proposed lifecycle rules are not claims of existing functionality.

Field-map SHA256: `25706DAF75736C1E9ECEC54D36FB0B09A4F1340496B185A14D25D47EA5700B0B`.

Public contract/renderer source is pinned to f0fc06a9. Current owner-side implementation is inspected at integration 21977bff without checkout or merge. Line anchors for owner code below refer to 21977bff; public anchors refer to f0fc06a9. Resolve symbols if a later branch moves lines. This map covers catalogue fields and explicit required Store gaps, not every unrelated app domain.

1. **Owner editor:** `apps/mobile/lib/features/work/screens/work_workspace_dashboard_screen.dart`, `_WorkspaceCatalogueSurface` (12465), `_CatalogueProductEditorState` (14832), `_save` (14929). Existing inputs include product name/brand/category/variant/pack/SKU/barcode, purchase cost (PRIVATE), selling price/MRP, stock/stock mode, minimum order, delivery, origin, returns/composition/regulatory note and visual label. Custom IDs are local; master-catalogue match guards the editor's public flag. Save requires core labels, purchase >0, selling > purchase, nonnegative stock/low-stock threshold, MRP >= selling, delivery and positive minimum order. These are client checks, not a qualified server publication contract. Origin's blank-to-India fallback is not a verified origin fact.
2. **Save and visibility:** `work_session.dart:7618 addOrUpdateWorkspaceProduct`, `7690 retireWorkspaceProduct`; both update local operational state. Availability `6606`, trading controls `6637`, delivery settings `6728`, Store visibility `6834` are existing separate setters. The quick public toggle at dashboard12797 checks positive price/availability, whereas the full editor also checks canonical match: reconcile this asymmetry before publication. `_persistOperationalState:6563` explicitly keeps changes on-device when orderOperations exists because Store sync is unavailable. Otherwise it sends a private operational snapshot through saveOperationalState; that snapshot contains business data and MUST NOT be the public catalogue DTO.
3. **Owner preview/projection:** `work_models.dart:4289 WorkspaceCatalogueItem`; `published:4350` gates publicListing, available and stock/availability-only. `toBuyPublicProduct:4355` projects price, identity labels, store-name seller, policy and basic display facts but does not carry stable storeId, product media, compliance, protection, grant, freight or manufacturer verification. It hardcodes Verified retailer; this must not substitute for authoritative verification. `toBuyPublicFacts:4387` additionally gates Store visible/accepting state. Dashboard `_CustomerStorePreviewSurface:15624` is an owner-local preview; its visibility label is not proof of consumer publication.
4. **Public consumer providers:** `buy_v2_models.dart` and `buy_v2_content_contracts.dart` define reusable contracts. `BuyV2CataloguePageSource` loads Store/product pages and exact identities; `publishedCatalogueSource` offers, facts/content/trust adapters and comparison source are separate authorities. Session constructor defaults include review/static adapters; `journey01/journey_router.dart:253` at integration creates `BuyV2Session(core: buySession)` without the owner publication adapter. Work procurement's review adapter is a private procurement bridge, not public Store publication. Thus **owner edit/save â†’ acknowledged published revision â†’ consumer catalogue refresh is missing/unqualified**.
5. **Partial older retailer path:** `retailer_home_screen.dart:592` and `RetailerSession.saveCatalogueProduct:573` edit stock/buy/sell; authenticated gateway reaches `backend/functions/src/workspace/workspace_profile_service.ts:283`. That backend handles only `atta`, and `retailerStore:436` emits a fixed Aashirvaad 1kg product. This is not a general multi-SKU Store publication backend. Older settings/campaign review gateways likewise do not establish published catalogue offers. Reuse valid contracts; do not mistake these fixtures for a completed owner flow.

Store logo/banner, description, explicitly public contact, full address/service area, hours/cutoff, fees and visibility lack a fully traced owner-to-consumer publication path; the final CSV rows identify these gaps. Product media binding and admission rules already exist (exact SKU/variant association, supported formats, size/dimension/count/derivative constraints), but no qualified owner upload/publish lifecycle is established here. Keep illustration/unavailable labels truthful. Trust ratings, manufacturer verification, grant eligibility and canonical product identity retain system/platform/moderation authority, not freely editable seller assertions.

## Boundaries and focused acceptance for the catalogue owner

Reuse the Work Store model/editor/session, public contracts and existing Buy consumers. Store-owned offer price, quantity, availability, fulfilment and policy must flow through an authorized, allowlisted published revision. Canonical product facts and system/moderated fields keep their own authority. Do not serialize private purchase cost/margin, stock alert settings, ledger/customer records, KYC, credentials, staff access or internal notes into a public response. New public contact fields require intentional owner publication; do not expose account contacts by default.

The Store/catalogue owner must supply the missing acknowledged save/publish/unpublish transport, stable Store+SKU identity and revision/freshness semantics; the public Buy owner must bind those published providers and refresh consumers without losing page/query/cart context. Shared routing/rotation is a separate pending defect. This handoff transfers source facts and dependencies, not authorization for backend implementation or changes outside the assigned lane.

Required focused checks for later implementation (NOT executed now): owner edits remain private until successful publish; publish failure preserves editable draft and last published revision; two owners cannot modify each other's SKU; update refreshes matching Store/Shop/Wholesale/Offers/detail and current-price consumers; unpublish/Store hidden/closed/unavailable removes discovery and rejects new purchase admission without rewriting historical orders; stale pages/quotes refresh truthfully; private-field serialization is rejected; media belongs to exact SKU/variant and withdrawn media disappears; authoritative verification cannot be spoofed. Check nonnegative/valid money and quantity with explicit units, long multilingual metadata, missing optional fields and offline/retry/idempotency. Reuse existing Work gateway/atomic/layout and Buy tests; their presence is not a new passing run.

This handoff performed source tracing, field coverage/original-row preservation checks, source/archive byte comparisons, evidence checksums and Git gates. No claim of live provider, production readiness or new device closure follows. Leave C04/C06/C07 pending until separately resumed and qualified. Codex should read this exact committed handoff before choosing its catalogue implementation baseline; delivery to the other chat is not asserted.

## Preservation appendix and exact read instructions

Evidence archive commit `3351e8d1e4c2516c39ee648c08baa874156afe0e` contains the SKU archive plus the V6 evidence commit `d2c8a26fadbdd488eef5f35c27bb98873b4cbdc3`. V6 preserved 2,875 raw non-APK files and three initial metadata files; follow-up adds the request/receipt and refines the map validation. All 1,537 EVIDENCE.csv records were rechecked against original bytes/size/SHA256: zero missing or mismatched. V6 MANIFEST.json SHA256 `335D28F8125A655FB2DC185B62F36AC1523D9452F38BEC6523F769E5F241EAFC`. Pattern checks found no supported private-key/token patterns; this is not a universal security certification.

Six historical APK binaries, each approximately 211 MB and above regular Git's file limit, remain untouched at their exact local paths. The V6 MANIFEST.json records every path, byte size, SHA256 and explicit hash-only disposition; their binaries were not pushed. One tool font input is similarly inventoried in the SKU manifest. No file was silently omitted or deleted. Existing APK source/build/signer/install provenance remains in the archive and tracked documents. This distinction must remain visible in any later retention decision.

Read from the final handoff commit: `docs/quality/cursor-redmi-v6-audit-20260913/HANDOFF.md`, `PUBLIC-DATA.csv`, current end of `DEFECTS.md`, `scope-state.json.catalogueHandoff20260916`, and UAT/EVIDENCE for specific qualifications. Read archive3351e8d1 path `docs/quality/preservation-20260916/cursor-redmi-v6-evidence/` for `MANIFEST.json`, `CURSOR-COMMIT-LEDGER.json`, `FIELD-MAP-VALIDATION.json`, `V6-ARCHIVE-RECEIPT.json` and `FOUNDER-HANDOFF-REQUEST.md`. SKU raw files are at sibling `cursor-redmi-evidence/` in the same archive tree. Use exact Git objects; no branch integration is implied.

The final clean/live-remote-equality receipt is saved after the documentation commit at `C:/GUARANTEED OUTCOME/MOOLSOCIAL-CURSOR-BUY-UAT-20260905/sku-metadata-redmi-20260914/catalogue-handoff-preservation/final-git-handoff.json`; it binds the final commit without a self-referential commit hash in this document.

---

# Historical checkpoints (preserved verbatim; current status above takes precedence)

# Founder-requested Redmi evidence checkpoint and paused audit handoff

Status: PAUSED AT FOUNDER REQUEST; AUDIT INCOMPLETE. No implementation, new APK or additional device testing is authorized by this handoff. Await the founder's next explicit implementation goal. This is an evidence-reuse checkpoint, not a product release, ticket closure or new policy/checker change.

## Exact tested identity

- Lane: Cursor Redmi; branch `work/cursor-ui/redmi-v6-audit-20260913`.
- Worktree: `C:/GUARANTEED OUTCOME/MOOLSOCIAL-WORKTREE-CURSOR-redmi-v6-audit-20260913`.
- Preserved V6: `da4d266f97b4081f55bd98f1e9522f25bc8ee05f`.
- Sealed audit source/evidence checkpoint: `f771d27b78e223e23b6f88025b8c67930097b542`; live remote equality and clean state verified before creating this handoff.
- Candidate: `UAW-CURSOR-REDMI-V6-REVIEW-20260913`; package `com.moolsocial.app.cursorreview`; version `2026091301 / 1.0.0-r66.19-cursorreview`.
- Redmi only: `TG8HCYTGGQT885OF`; Android13; physical720x1600, density320, normal font1.0; individual enlarged-text evidence remains limited to recorded cases.
- APK SHA256: `97750AD544EB9E77D5732A3C49ECDB530E59DF6F64AE764A8CFD02382657A4A7`.
- Signer SHA256: `CBDFC5969AD51ED570AFB1CF2FE60377E559D43F59D59E2AB66CCAF78EA9AC25`.
- Review/debug build only; no production/provider qualification. Build, admission and installation provenance remain in PREBUILD.md and apk-regression-state.json.
- Fresh checkpoint comparison: `git diff --quiet V6 HEAD -- apps/mobile` returned0; mobile application/test/asset tree unchanged from V6.

## Passed-check reuse gate requested by founder

The authoritative passed set is EXACTLY the 514 `device_pass` records in the pinned JOURNEYS.csv below. Each record includes its ID, precondition, tested action, expected and actual result, destination/return evidence, source owner and remaining limitations. Reuse those records instead of running the same unchanged test again. A row is not a claim that every tap, alternate state or entire journey family passed.

Before repeating a passed case in a later authorized goal, identify the specific reason and affected record IDs: relevant application/dependency/route or configuration change; changed APK behavior needing verification of the implemented fix; new contradictory evidence; missing or invalid evidence; or an explicitly requested broader state/device check. Retest the changed/affected case and connected risk paths, not the whole frozen set without a reason. A new case must state how its precondition/action/destination differs from the existing record. Compare both results when later evidence contradicts an older narrow pass; do not silently discard either or treat the older pass as a closure.

The 25 failure records map to 22 deduplicated open defects. They are NOT part of the passed set. Observations, provider/authentication/test-data blocks, unreachable source paths and excluded real actions are NOT passes. Historical pre-V6 closed tickets are excluded. Host/source inspection is not physical Redmi evidence.

Preserve the indexed captures and the old record IDs. Future implementation must carry exact defect IDs and use the recorded original reproduction plus justified connected regressions. This checkpoint authorizes no implementation, ownership expansion, safeguard exception or change to existing gates.

## Verified totals and coverage limits

- 22 distinct open defects; 2 high, 9 moderate, 11 minor.
- 628 action/check records, including514 passes,25 failure records and20 device observations. These are not628 unique taps or end-to-end journeys.
- 1175 physical numbered captures;1177 total indexed evidence artifacts. Every indexed artifact was read and its byte length/SHA256 rechecked for this checkpoint:1177 checked,zero missing or mismatched.
- 58 blocked records:27 provider,22 test-data,9 authentication. These are a subset of pending qualification, not a total pending-case denominator. Provider-blocked does not prove the backend is absent.
- Other dispositions:4 source_unreachable,1 source_gap,4 data_observation,1 scope_boundary_observed,1 excluded_authorization.
- 71 public-data mapping rows. Mapping is incomplete; no claim of a complete Store-to-public-Buy contract.
- Full semantic journey inventory remains incomplete. Remaining shared Chat/account/address/mini-cart cases and alternate/error/recovery/accessibility/persistence states have not all been enumerated and physically qualified. Existing UAT group tables and each record's remaining column retain known gaps.
- No further testing was performed after the founder requested this checkpoint and defect handoff. The last completed physical round is169.

## Preserved device/user state

Last capture1175: Scheduled Shop, saved wheat badge1 and empty cart. Original Home/Work addresses and Work selection preserved. Tracking alerts temporarily paused then restored On1173;OS notification permission unchanged Off. Delivery Hide/compact bike9+ restored1170;Keep and sound remain Off;tracking scroll top1174. Existing unsent drafts retained;no message/order/payment/authentication/provider transaction, data clear, reinstall or force-stop in the checkpoint round. No pending execution handle remains from these checks.

## Open defect index

Full reproduction, expected behavior, impact, exact captures and source correlation for every ID remain in [DEFECTS.md](DEFECTS.md). This index is for handoff; it does not replace the full evidence.

| ID | Severity | Customer-visible defect | Ownership/dependency boundary |
|---|---|---|---|
| RV6-D001 | Minor | Store empty-search guidance suggests an area control that is absent | Buy contextual recovery copy |
| RV6-D002 | Moderate | Removing the final cart item while in a Store exits the Store catalogue | Buy cart/session and Store modal lifecycle |
| RV6-D003 | Moderate | Chat, invoice PDF and shopping alert present stored relative delivery estimate without freshness qualification | Buy metadata/invoice/alert and shared Chat contract;live ETA separately unqualified |
| RV6-D004 | Minor | Invalid display-name guidance is clipped at normal text size | Connected shared profile form |
| RV6-D005 | Moderate | Selecting Hindi leaves observed Buy/preferences UI English without limitation disclosure | Shared localization and Buy strings;scope must be explicit |
| RV6-D006 | Moderate | Cancelling sign-in then Back exits to launcher instead of originating Buy | Shared Security/sign-in routing;no auth-flow duplication |
| RV6-D007 | Moderate | Related-product Back skips previous product detail | Buy product navigation/session |
| RV6-D008 | Minor | Wholesale buyer-type label touches business-name value | Buy tracking details layout |
| RV6-D009 | High | Confirmation deep link says Order placed with no confirmed purchase and empty cart | Buy/shared route admission and confirmation identity |
| RV6-D010 | Minor | Recovery return retains order but selects Shop instead of originating Orders | Buy recovery destination/return context |
| RV6-D011 | Minor | Wholesale details repeat pack/variant/price/policy through several sections | Buy content deduplication;preserve distinct supplier facts |
| RV6-D012 | Minor | Closed Store lists its non-orderable products as available | Buy Store catalogue count wording |
| RV6-D013 | Minor | Store Chat context expansion adds only empty space/divider | Shared Chat context presentation |
| RV6-D014 | High in review APK | Warm order link over Store modal produces navigator lock assertion and wrong recovery | Shared route/Buy modal integration;release behavior unverified |
| RV6-D015 | Moderate | Recently viewed shows enabled Add for closed/unavailable products without visible rejection guidance | Buy history row availability/feedback;retain session purchase restrictions |
| RV6-D016 | Moderate | New Shop offers alert opens ordinary Shop instead of Offers | Buy alert destination wiring |
| RV6-D017 | Moderate | Selected saved GST chip identity is unreadable | Scoped Buy chip/theme interaction;shared theme needs separate owner assessment if changed |
| RV6-D018 | Moderate | Product Back leaves paginated search for main catalogue | Buy exact search-surface return;internal page retained,not lost data |
| RV6-D019 | Minor | Minimized delivery rail shows collapse chevron instead of bike/count | Buy tracker state presentation;reopen still works |
| RV6-D020 | Minor | Message-audience sheet clips last privacy option explanation | Shared Chat settings sheet/system inset |
| RV6-D021 | Minor | After last item removal catalogue keeps expanded quantity spacing | Buy product-grid sizing/state refresh |
| RV6-D022 | Minor | Shopping area chooser does not indicate selected city | Buy area selection presentation;filtering works |

## Exact evidence bindings

The SHA256 values below bind current preserved working-file bytes at the sealed checkpoint (Windows line endings may differ from Git blobs). Git blob IDs bind the committed content at the full checkpoint SHA above. Do not infer absence of a file change from a filename alone.

| Owner | Working-byte SHA256 | Git blob at checkpoint |
|---|---|---|
| JOURNEYS.csv | `A72D70FCED8F3B7C0C489867681D7DADA0D90CB8D3C105DE304EBB3BECE13767` | `c11686dfb11851b6b7ec536efc6b4b62127b51cc` |
| EVIDENCE.csv | `EAA7479ECFD8B8DE6B13530DF6D642E787F05910751F493329E827AC2E0670AD` | `3c0738dc60da12d753fb27c58037458ee61beae4` |
| DEFECTS.md | `88DBEF239845211693384134C82F214F32D9DB0C97AAAA83D2E899F951382901` | `e7f7bc5d3a75e30c922a7f26303204c63fa11f90` |
| PUBLIC-DATA.csv | `997887F8FC54885091CA72BA477E375976E1D71F5A45E9999AF256495B58F23B` | `569c57dbae14839db99543a178d7b4205cb6b724` |
| BLOCKERS.md | `B9CAA58B66F571D3FDB91FCEED16EFCA6719AA75102651F78B64E8AD881ED9E1` | `2470b3a5bb27df825da797e0ee2b096dd57656cb` |
| UAT.md | `BEB3DF806090597BBFEFAA5EBCF037CD9C84A4C7D5C493C239AD347AA1706DA0` | `dfefabbcf5588c95ce7d9ea11b6aa7cf9216d8a5` |

## Stop boundary

The founder requested a pause after this evidence checkpoint and detailed defect list, before setting a new implementation goal. Audit completion is NOT claimed. Do not continue device testing or start fixes automatically from the former audit objective. Resume only under the founder's new explicit instruction, preserving this checkpoint and its incomplete/blocked dispositions.
