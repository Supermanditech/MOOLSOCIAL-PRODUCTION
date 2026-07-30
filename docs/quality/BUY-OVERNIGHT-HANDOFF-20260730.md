# Buy overnight checkpoint and resumed handoff — 30 July 2026

## Preserved repository state

- Branch: `remediation/prototype-conformance-2026-07-20`
- HEAD: `5225bb8d36792cc8f7fb9dfcfe418b3f93b7ca1a`
- Commit, push, merge, deployment and publication: not performed.
- Every tracked modification, untracked file and evidence artifact was
  preserved. The complete 8,328-line working-tree status is recorded at
  `artifacts/quality/buy-overnight-handoff-20260730-17/working-tree-status.txt`.
- The 12 tracked changed files are recorded in
  `tracked-changed-files.txt` beside that status.

## Protected baselines

- Founder-final Buy HTML/reference remains unchanged and read-only.
- Native Flutter R19 remains the device-verified founder-review baseline:
  `artifacts/quality/buy-flutter-r19-founder-remediation-oppo-20260730-09`.
- R19 candidate and installed-base SHA-256:
  `99D2032A4D173E13471ABACFD54BE36262F11552D99B8B882CB407723DB183BE`.
- Screens 01–03 and Social were not changed.
- Final protected-Social check passed at handoff with exact tree:
  `54851b4769c6a0087f586ce6c9325bbee1d7c790e06488eccae3a62ca953332e`.
- Final approved-lock and brand-integrity checks passed.

Founder acceptance of R19, commit authorization and release authorization
remain pending.

## Completed post-baseline production tickets

1. `BUY-FV2-053` — unknown product/order/address identifiers fail closed.
   Two affected regressions passed 85/85; R21 checksum-matched OPPO evidence is
   under `buy-post-r19-hardening-20260730-10`.
2. `BUY-FV2-054` — independent Shop, Wholesale and Medicine catalogue
   contracts plus read-only backend gap audit. Two regressions passed 91/91;
   evidence is under `buy-post-r19-vertical-contracts-20260730-11`.
3. `BUY-FV2-055` — order-card body and accessibility action now agree for
   Track/Reorder. Two regressions passed 92/92; R22 OPPO evidence is under
   `buy-post-r19-order-card-action-20260730-12`.
4. `BUY-FV2-056` — unknown saved-prescription IDs authorize nothing. Two
   regressions passed 93/93; R23 OPPO evidence is under
   `buy-post-r19-prescription-id-20260730-13`.
5. `BUY-FV2-057` — reorder restoration preflights all product IDs and vertical
   ownership before any cart mutation. Two regressions passed 94/94; R24 OPPO
   evidence is under `buy-post-r19-reorder-integrity-20260730-14`.
6. `BUY-FV2-058` — mixed-cart fulfilment/order projection contract coverage.
   Two regressions passed 95/95; checksum-matched R24 replay evidence is under
   `buy-post-r19-checkout-contracts-20260730-15`.
7. `BUY-FV2-059` — checkout rejects unsupported payment identifiers while
   preserving the prior payment and address. Two regressions passed 96/96;
   R25 evidence is under `buy-post-r19-payment-allowlist-20260730-16`.

Each ticket passed focused analysis/tests, two same-source affected
regressions, founder-final Buy reference, customer-copy,
interaction-contract, approved-lock, brand-integrity and protected-Social
gates. Each device ticket has screenshots/UI trees, app-scoped logcat,
fatal/ANR assertion, version evidence and candidate/installed checksum proof.

## Latest installed candidate

- R25 versionCode: `2026073025`
- Candidate and device-computed installed SHA-256:
  `2CF071BB363D477908649C52835692BEE5403838C71A07690E203175670E8DB5`
- Last verified OPPO result: payment sheet exposed exactly `UPI`,
  `Bank transfer` and `Purchase order`; selecting `Bank transfer` returned to
  Review order with the same selection; zero app fatal exception/ANR.

The OPPO disconnected from ADB after this proof. No installed state was
altered afterward.

## Founder design input received after Ticket 059

The founder requested a new comparison of MoolSocial Buy against Blinkit,
Zepto, Amazon and Flipkart for:

- address, search, account and category placement;
- a prominent but non-obstructive cart;
- healthier vertical spacing;
- MoolSocial-owned product/service promotion cards;
- a smaller or more distinctive brand treatment; and
- consistent application across Shop, Wholesale, Medicine and Orders.

Existing OPPO references remain preserved:

- Blinkit:
  `artifacts/quality/buy-flutter-founder-remediation-oppo-20260729-06/01-blinkit-home-inspiration-oppo.png`
- Zepto:
  `artifacts/quality/buy-flutter-founder-remediation-oppo-20260729-06/03-zepto-home-inspiration-oppo.png`

Fresh Amazon and Flipkart OPPO captures were not taken because the device
disconnected and the implementation cutoff had already passed. No subjective
UI/UX or layout code was changed. The next session should reconnect the OPPO,
capture those two live references, complete a founder-review proposal, and
obtain explicit approval before changing the R19 visual baseline.

## Remaining risks and decisions

- Founder visual acceptance of R19/R25 remains pending.
- The requested promotion cards need reviewed content, route, disclosure and
  frequency before implementation; no advertising behavior was invented.
- The Buy backend gap remains: the repository backend is YouTube-specific and
  has no established Buy API/data contract. No speculative backend was added.
- Real inventory, price, payment, order, prescription and delivery services
  remain external production dependencies.
- Fresh Amazon/Flipkart reference capture is pending OPPO reconnection.

## Resumed work

At handoff there were no Flutter, Dart, Java or Gradle build processes.
At 10:19 IST the founder explicitly canceled the earlier 07:30/08:00 cutoff
and shutdown instructions and resumed work. A Windows shutdown abort check
confirmed that no shutdown was pending. Development therefore continues from
this exact preserved checkpoint.
