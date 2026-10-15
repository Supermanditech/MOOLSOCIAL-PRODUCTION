# LF-01 — Buy/Store entry and recovery

Status: first bounded application correction implemented and hot-reloaded on
OPPO; focused host checks passed. Founder acceptance remains pending. Date:
15 October 2026 IST. Batch 02 has not started.

Actor: a MoolSocial account holder entering Buy or its approved Retailer/Grocery
Store. Capability: enter and return to the intended account/Store context without
losing existing Cart or Store drafts or exposing another account's work.
Classification: mvp_required; this is safe access to existing commerce, not a new
screen, role, authentication provider or backend service.

## Founder authority and boundary

The founder requested the ordered frontend batches, then said "start
implementation" and authorized multiple subagents. The founder clarified that
the combined baseline is owned by Codex Desktop until a later Cursor worktree
and work split, and approved narrow LF-01 activation from accepted combined
3c5a454bf8af173d9736c75213cafb88e641765c. After the inherited checker blocked this
new ticket, the founder allowed only minimal governance and said "continue".
This permits correcting existing task admission, not weakening safety checks,
expanding scope or claiming old integration authority as new frontend acceptance.

Use one application writer. Other agents may provide context-only reviews until
an exact read-only assignment is admitted. Preserve the accepted integration and
Cursor branches, all saved data, old approvals, policy and history. No new
qualification framework, historical replay or data reset. No Batch 02 before
Batch 01's tested OPPO preview and explicit founder approval.

## Reuse and minimum complete change

Trace the existing journey router/session, Store session/procurement controller,
Buy session and their focused tests. Establish a failing observable case before
changing behavior when practical. Fix only demonstrated entry, sign-in return,
Back or account-safe recovery gaps. Do not rewrite approved layouts, add routes,
replace state owners or rebuild passing persistence. The machine scope record
lists exact owners; source presence is not evidence of a defect.

## Acceptance and failure behavior

1. Buy and Store Restock retain distinct purpose, Cart and return context.
2. Sign-in returns to the intended permitted destination; cancellation returns
   safely without authenticating or adopting a different Store.
3. Account switch/logout invalidates late asynchronous recovery/navigation; no
   foreign Store, Cart, draft or pending result becomes visible.
4. Android Back and leave/return preserve the owning draft and saved identities.
   Destructive decisions require the existing explicit safeguard.
5. Missing/unapproved Store identity stays unavailable; local evaluation records
   never confer live account approval. Backend access enforcement remains deferred.
6. Run relevant focused/impacted regressions and inspect actual affected screens.
   Separately label host fixtures, hot reload, restart and actual APK evidence.
7. Present Batch 01 on OPPO and await approval. Retained records must originate
   through the application; do not inject runtime products or transactions.

## Exclusions

Backend/auth-provider implementation, KYC approval, public publication, payments,
dispatch/settlement, delivery-operator workspaces, promotions, analytics redesign,
native dependencies, APK build/install, production transactions and later LF
batches. Existing r67.3 APK acceptance does not qualify new source or live services.

## Admission correction

The previous checker couples every new task to a closed 83-binding integration
identity. LF-01 uses its own exact current-ticket record through the existing
MVP state-path mechanism. Only this feature branch/root/ticket may use the new
admission path. Preserve the previous path for all historical tickets unchanged.
Keep accepted-baseline ancestry, literal changed-owner checks, registry generation,
Git operation/history protection, clean boundaries and existing secret checks.
This is task admission, not a passing application test or UI acceptance.

## Application correction and current verification

- Reproduced: cancelling sign-in while a provider result is pending changed the
  session to ready and cleared its Buy destination. A successful provider result
  could then be reported without completing the local authenticated session.
- Smallest correction: `cancelSignIn` now rejects cancellation while busy. The
  existing router Back interception remains installed; normal cancellation is
  available after a provider failure/cancellation. No approved screen changed.
- Added two deterministic, host-only delayed-provider regressions in the existing
  JourneySession test: authenticated completion retains the intended Buy Cart
  route; provider cancellation restores normal Back to the Store origin. Both
  failed before the correction and passed afterward.
- Corrected two stale Buy router test assertions from the removed `PURCHASES`
  heading to the existing Orders view key. No Orders UI or behavior changed.
- Full JourneySession plus Buy router pass: 58 tests. Additional focused existing
  Store draft/restart, account/session isolation, procurement and retained Back
  checks pass: 40 tests. Analysis of the changed Dart files: no issues found.
  These are host fixture results, not production/provider acceptance.
- OPPO 2b3e0f71: attached to existing debug runtime r67.3, no APK build/install or
  data reset. Reloaded one library; read-only VM inspection confirmed the actual
  running `cancelSignIn` contains the busy guard. Initial zero-library reloads
  were not treated as proof that the correction had loaded.
- The existing consumer Cart remained one Herbal bathing soap pack, INR 164,
  with its prior payment-review hold intact. Existing Store/Stock opened as
  TEST Store · product entry; saved oil 7 and OPPO37E rice 97 remain visible.
- Buy stock correctly refuses this unbound evaluation account: "Your Store
  account is unavailable. Reopen the Store before buying stock." A connected,
  approved Store procurement journey remains provider/account-dependent; it was
  not fabricated or declared device-passed. The current notice uses a green
  success treatment for an unavailable message; record as a presentation issue,
  not evidence that procurement succeeded or authority to redesign this screen.
- No orders, payments, stock changes or invoices were created. Origins of old
  evaluation records were not newly established. Device restart persistence and
  live delayed-provider authentication were not retested in this round.

Review artifacts are in the calling task's existing outputs folder:
`lf01-before-review-20261015.png`, `lf01-workspaces-20261015.png` and
`lf01-restock-latest-20261015.png`. They are observations, not founder-approved
references. Acceptance is pending; retain backend/provider limitations above.
