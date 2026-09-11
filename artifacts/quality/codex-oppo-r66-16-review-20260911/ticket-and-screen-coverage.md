# r66.16 bounded support review disposition

## Latest native085 — Restock retention tested;14 native findings

Existing APK Store Restock > exact product > minimum2packs > cart > Back, bread search > exact product > Back, originating Store return/reentry, and2to3pack update/cart reconciliation passed the observed default-font in-session checks. Query, product, quantity and ₹1,440/₹2,160 totals stayed consistent. Evidence: device-review.md/native069–085, manifestv5. This qualifies neither process-death/account switching nor deferred procurement authority/Cursor integration/physical200%.

**R6616-UAT-CART-OVERLAY-14**: product-page floating Cart covers the quantity value and Add one action (073/075/079). Link to existing REG4324/REG4396; do not create another global root-cause record or edit Cursor code. Implementation held. Later acceptance: product quantity controls and Cart independently visible/reachable at default and large text across embedded Store and ordinary Buy, with retained cart/navigation and safe overlay positioning. Catalogue increment workaround does not close it.

Current audit inventory:14 native/customer-facing findings,1 narrowly closed and13 open; plus1 open review-only QA recovery defect with a safe existing-UI workaround. All27 original items remain mapped; untestable backend/fixture/accessibility/shared-owner checks are explicitly pending, not passed. Earlier counts below are historical checkpoints.

## Latest native068 — safe existing-UI recovery verified

Store testing is no longer blocked by lack of dashboard access. Earn Today > Create your Workspace starts a separate QA application; the existing explicitly labelled review-only Approved control opens its dashboard. Native068 confirms the previous OPPO-QA-Cloud-Document application remains Under review and the other saved application remains listed. No new APK, data clearing, source change or production approval bypass occurred. This corrects the stronger blocker conclusion below; historical observations remain evidence. R6616-QA-RECOVERY-01 is still open, with this verified workaround, not a product fix. See device-review.md/native049–068 and manifestv4. Continue the remaining reachable Store tests; do not count unexecuted Restock/product/cart/Back checks as passed. Customer findings remain13 total,1 narrowly closed and12 open; one separate QA recovery defect remains open.

## Founder-requested test-setup defect — R6616-QA-RECOVERY-01

Status: registered, implementation held. This is an additional review/test-setup defect, not another customer-facing product defect and not an addition to the original27 product scope. Current inventory:13 historical customer-facing/native findings (1 narrowly closed,12 open), plus1 open QA recovery defect.

Actor/outcome: Codex testing the retailer Store in the isolated OPPO review APK must recover an already submitted synthetic application after process restart and explicitly select an approved QA state, without clearing data or granting real approval. Actual: the retained application survives but ReviewWorkGateway's in-memory case allowlist does not; normal entry can only resume pending review, and the dashboard guard correctly denies access. Exact reproduction/native042–048, affected review-only source and manifestv3 hash are in device-review.md.

Later acceptance: recover only known synthetic cases under the existing debug plus both review flags; retain explicit reviewer state selection; preserve application identity and user data; production gateway/build must never gain approval controls or an approval bypass. Verify restart, unknown case, wrong identity, missing flags and unchanged real approval guard. No implementation, runtime data mutation or new APK is authorized now. Continue reachable native cases; keep dashboard-dependent checks blocked rather than count them as passed.

## Latest continuation048 — no fixes, no APK

Pending-application recovery and direct dashboard denial were tested on the unchanged installed r66.16. The dashboard guard correctly blocks access without a verified workspace. Restart removed the review gateway's in-memory test-approval eligibility; the retained pending application exposes no test-state control or fresh submission. Restock product/cart/Back replay therefore remains unexecuted in this continuation. See device-review.md/native042–048 for observed routes, source classification and hash-bound evidence. A permitted approved-QA-state recovery or later authorized fixture correction is needed; do not clear data, bypass approval or create a new APK. Counts remain13 historical native findings,1 narrowly closed,12 open; all27 remain accounted for, not fully qualified.

## Latest 27-item audit disposition — native041

Testing/recording only; no more APKs or implementation. All27 original items remain accounted for below. This is not a claim that all27 are fully device-qualified. Items1–22,25 and26 have related OPPO observations;23/27 are host investigations;24 is held. Existing source/build is unchanged.

| # | Original item | Device outcome / remaining boundary |
| --- | --- | --- |
| 1 | DASH-LOAD-01 queue | 12/100/1000-record populated queues and last-order reachability exercised. Continuous server events unavailable. |
| 2 | DASH-LOAD-02 exact search | Order/customer/invoice identity and Back tested. Children05/06 affect central order details. |
| 3 | DASH-LOAD-03 alerts | Mixed-state targets and count changes tested. External arrival/reordering fixture unavailable. |
| 4 | DASH-LOAD-04 independent commands | Simulated acceptance rejection, lost reply, reconciliation and reject confirmation tested. Child05; no backend concurrency claim. |
| 5 | DASH-LOAD-05 deadlines | Expired actions disabled and acknowledged extra time tested. Real capacity/reassignment unavailable. |
| 6 | DASH-LOAD-06 fulfilment | Packing persistence and explicit ready tested. Children06/07; authoritative collection/rider handover pending. |
| 7 | DASH-LOAD-07 suppliers | Nine stages, exact return and isolated shipment drafts tested. Children02/08; authoritative receipt/Buy tracking pending. |
| 8 | DASH-LOAD-08 finance | Populated amounts,100/1000cr figures and local invoice sales/settlement separation tested. No real payment/settlement. |
| 9 | DASH-LOAD-09 returns/issues | Missing-pack draft and cross-shipment isolation tested. Receipt/issue submission unavailable, not a passed completion. |
| 10 | DASH-LOAD-10 history |1000 Sales rows reached; local stock entry refresh tested. Child10 tab-position loss; authoritative history unavailable. |
| 11 | DASH-LOAD-11 offers | Three eligible-role offers and retained selection tested. Commitment/payment/revision responses unavailable. |
| 12 | DASH-LOAD-12 communication | Order/store Chat context and Back tested; exact support retry now tested. Real recipient/service delivery unavailable. |
| 13 | DASH-LOAD-13 daily actions | Existing first-tap stock/sale/invoice/search/supplier/finance/offers tested. Children02–04/07/09 remain. No external publishing or messaging. |
| 14 | DASH-LOAD-14 durability | Contact/business restart and in-session drafts tested. Children03/10/12/13; volatile review Store membership is a separate fixture limitation. |
| 15 | DASH-LOAD-15 mixed load |1000 records with supplier/offer/finance states and selected commands exercised. Child05; no real burst-throughput claim. |
| 16 | FIRST-02 / REG4558 Stock tools | Normal/160% and keyboard save tested. Child09 remains. |
| 17 | FIRST-03 / REG4559 counter phone | Invalid/valid phone, review/Back and unsent local invoice tested. Backend verification/physical200% not qualified. |
| 18 | FIRST-04 / REG4560 inline Chat | Search/recovery/context and Back tested. Transport/TalkBack remains unqualified. |
| 19 | REG4554 Files heading | Normal/160% heading/Add checks retained. Physical200%/TalkBack unqualified. |
| 20 | REG4556 Files Cancel | Cancel/Back checked. Child11 global Choose file no-op; Workspace uploader success does not close it. |
| 21 | REG4549 support drafts | Unsent/failed draft Back recovery and synthetic A/B isolation pass. New child13: unsent draft lost after restart. |
| 22 | REG4550 support Retry | Simulated error, retained draft, keyboard-open Retry, one-message completion and retry after Back pass in r66.16. Physical200%/real transport not qualified. |
| 23 | REG4555 shared regression | Host investigation, not an OPPO screen. Retained classification; no invented device pass. |
| 24 | FIRST-05 / REG4561 product add | Founder-held separate redesign; not implemented or qualified by this batch. |
| 25 | Physical200% / TalkBack | Device160% and partial TalkBack observations retained. Ordinary device Font UI did not offer200%; assistive gestures/audio remain incomplete. No security bypass. |
| 26 | Cloud-file completion | Authorized Drive image/local two-page PDF, preview/zoom/cancel/Back tested. Child12 restart metadata loss; provider error observations recorded, backend upload not qualified. |
| 27 | Seven exploratory assertions | Five Codex host corrections retained; two Buy/Chat assertions deferred with Cursor. Not an OPPO device-pass count. |

### Consolidated native child list

13 historical findings, one narrowly corrected/retested,12 open:
01 malformed phone prefix (corrected);02 stale procurement shortcut;03 promotion draft Back loss;04 requirement feedback offscreen;05 central-order nested scroll;06 missing purchased pack/unit-price snapshot;07 ready-state rider-request claim;08 supplier UTC/local freshness wording;09 Stock Save hidden after keyboard dismissal;10 statement tab scroll-position loss;11 global Files picker no-op;12 attachment metadata/preview lost after restart;13 support unsent draft lost after restart.

The new13th child is R6616-UAT-SUPPORT-DRAFT-13 / REG4549; exact native reproduction, source finding and evidence hashes are in device-review.md. Existing child details remain in the r66.15 ledger. Do not duplicate these by adding one new ticket for every affected parent.

Remaining full-acceptance barriers are explicit: backend/payment/collection/receipt authority, deferred Cursor dependencies, unavailable dynamic/receipt/commitment response fixtures, complete physical200%/TalkBack testing, held product-add scope, and the12 recorded open product findings. No additional APK is authorized to create missing scenarios in this round. Continue only reachable native checks without source changes; do not label these barriers as successful device tests.

Current stage: r66.16 built, checksum-matched installed, bounded native support recovery completed. See post-install.json and device-review.md. Founder reaffirmed testing/recording only after this install: no product fixes or further APK builds until the original27 device audit is accounted for.

Original27-item inventory and12 historical OPPO findings remain in ../codex-oppo-r66-15-review-20260911/ticket-and-screen-coverage.md and device-review.md (latest native224 checkpoint controls older counts). One malformed-phone behavior was narrowly corrected and device-retested; eleven findings remain open. This candidate does not close those unrelated children or the entire27-item batch.

REG4550: add controlled review-only failed send to make the missing OPPO support retry scenario reachable. Local normal/200% keyboard tests and actual renders pass after fixing test render timing. The earlier host-overlap product diagnosis is withdrawn, not promoted to an OPPO child.
REG4549: preserve exact-application identity, unsent drafts and reply/media context while observing failure/retry/Back. Existing regression coverage passes; pending native successor replay must prove actual observations, not infer from tests.

Native update035: REG4550 now has its missing controlled frontend failure scenario on OPPO: error/retained draft, keyboard-open reachable Retry and single-message completion pass. REG4549 same-application Back/reopen preserves both an unsent draft and a failed draft; retry after reentry also passes. No real transport was exercised. Application A/B switching, support process death and physical200%/TalkBack are not newly passed.

Original27 inventory now has24 items with related native evidence, two host investigations and one founder-held product-add item. Related evidence does not imply complete parent closure. Twelve historical native findings remain: one narrowly corrected/retested, eleven open; zero additional distinct device findings in this bounded continuation. No unsupported fixture/backend case is marked device-passed. Full per-item predecessors and explicit limitations remain in the r66.15 ledger; latest r66.16 support results supersede only its missing-error-scenario status.

OPPO plan: verify exact package/APK checksum, install without clearing data; open an exact synthetic review application support thread; arm one failure with keyboard closed; enter a clearly marked QA draft; fail only through ReviewChatSendGateway; verify error and retained draft; retry once; inspect single local message, no duplicate effect; navigate Back/re-enter and compare application A/B drafts; register genuine device defects. Do not send to real support or WhatsApp.

Backend authority/transport, unsupported receipt/offer/history event simulations, deferred Cursor procurement/Buy checks, physical200%/TalkBack and founder-held product-add redesign remain separate limitations. Report incomplete cases honestly; do not label all27 device-qualified from this bounded replay.
