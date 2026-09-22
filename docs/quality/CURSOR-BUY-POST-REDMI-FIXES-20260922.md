# Active Buy goal: post-Redmi fixes

Founder authorization, 22 September 2026: finish the bounded Redmi journey
coverage, then implement all outstanding session inputs, tickets and recorded
defects; validate locally and stop. Standing authority covers necessary goal
blockers. No governance or policy expansion. This supersedes the earlier
defects-only execution restriction; original audit evidence remains unchanged.

Branch: work/cursor-ui/buy-ready-20260921.
This Codex instance is the independent Cursor Buy lane. Routine Buy implementation
and testing proceed independently; shared contract or routing changes alone need
coordination. This is task memory, not a new governance mechanism.
Starting HEAD: 87bc96d4c28300146c9e2c3c3b37c7c3aacffed0.
The only pre-existing untracked file is the Redmi audit Markdown.

## Outcome and scope

Public Buy customers can discover and search a specific store, inspect its
products, choose filters and Saved items, understand cart and order information,
and reach existing checkout and recovery destinations without clipped controls,
misleading content or broken context. Launch-supporting corrections to existing
Buy owners; authentication and authoritative fulfilment remain required.

Reuse apps/mobile/lib/ui_v2/buy/buy_v2_catalogue.dart, buy_v2_views.dart,
buy_v2_screen.dart and buy_v2_design.dart, plus the existing Buy session/models
under apps/mobile/lib/features/buy when a defect originates there. Reuse focused
tests under apps/mobile/test/ui_v2/buy. No new screen, backend or data authority.
Inspect exact affected owners before each change; preserve shared contracts and
coordinate only an actual shared dependency. Store workspace, Counter Sale, CSV,
other worktrees, accepted references and native files are excluded.

## Execution and acceptance

1. Completed: identified Redmi audit queue, including 22 continuation combinations
   and 124 new screenshot/XML pairs (205–328). See
   CURSOR-BUY-REDMI-AUDIT-20260922.md for all 31 defects and original evidence.
   Provider/account/data prerequisites remain exact blocked cases, not passes.
2. Reconciled RB001–031 and earlier founder tickets against local post-APK
   fixes. Implemented the remaining bounded code corrections below; data and
   provider prerequisites remain open and are not represented as fixes.
3. Completed focused behavior, navigation, compact/large-text/inset checks,
   analysis and affected regression tests. Original failures remain in evidence.
4. Stop after local validation and a complete disposition of each recorded item.
   No new APK, installation, deployment, push or commit is part of this goal.

No fake quote, simulated authentication success, fabricated product identity or
live order/payment/message may be used to close a provider or data limitation.
Local validation does not constitute fresh Redmi or production acceptance.

## Validation findings (chronological working notes; final results below)

- r7 passed five visual journeys. Store/Recent PNGs use the app theme and show
  readable real text. The new publisher harness used default test typography,
  producing Ahem blocks; retain that rejected image, apply MoolTheme.light to the
  harness, and capture a new image in a different directory. Geometry pass alone
  was not accepted as visual proof.

- Saved r5 diagnostic proved the missing Remove target was not clipped: its
  product was excluded by the newly correct sale-type filter. The old test picked
  an arbitrary second Shop product from another fulfilment mode. Use two products
  from the same selected mode for the Add/Remove/Clear test and assert both are
  visible before interaction; keep dedicated sale-type exclusion coverage.

- r4 retained two failures: an old Wholesale trade-packs copy expectation and
  Saved's second Remove action not hit-testable after Add. Correct the repeated
  Wholesale wording to Wholesale packs; inspect Saved geometry before changing
  the reveal helper or accepting its journey. Original log is post-fixes-local-r4.log.

- Code review found that making the shared productsForOrder selector prefer
  historical lines would also feed old prices into Reorder. Keep snapshot
  rendering local to Items; preserve the current-product selector and add an
  old-price/new-price reorder assertion before closure.
- Offers r3 passed all four original keyboard/viewport cases after moving its
  border to foreground paint, retaining the measured text area and styling.
- r2 finished: 239 passed, one optional capture skipped, three Offers keyboard
  failures (subsequently repaired/replayed in r3). No other failures in that run.

- r2 exposed a 2px bottom RenderFlex overflow in the paged Offers keyboard
  checkpoint at 320x844 normal/2x and 640x360 2x. Original failure retained in
  post-fixes-local-r2.log; isolate the real owner and repair layout before
  acceptance. Do not remove the existing zero-exception assertion.

- Regression memory implementation check passed (4616 entries, 2550 applicable).
  Approved UI locks passed before changes. Neither checker/policy was edited.
- Local r1: 18 passed, 2 optional captures skipped. Includes order quantity/amount,
  Saved query/sale-type, Orders return and existing order/Saved regressions.
  Evidence: outputs/cursor-buy-redmi-audit-20260922/post-fixes-local-r1.log
  under the parent workspace. r2 broader affected tests are in progress.

## Local defect disposition (not fresh Redmi acceptance)

| Audit item | Current disposition |
| --- | --- |
| RB001, RB007 | Prior local Store information inset and unboxed search fixes retained. |
| RB002–004, RB020 | Prior filter inset, search relevance and compact selection/white checkmark fixes retained; current Store tests cover them. |
| RB005 | Generated review media now resolves the same exact template as product details. Actual supplier images remain a data prerequisite where absent. |
| RB006 | Orders/comparison return names and padded Store return label corrected. |
| RB008 | Saved/cart announcements, comparison names and chat display fields reuse validated customer copy; draft removes internal SKU and empty Brand. Structured IDs remain exact; no message sent. |
| RB009 | All-basket scope label clarified; floating cart subtracts the same selected coupon saving as Cart. |
| RB010 | Quantity editor uses existing pack text without redundant per-pack wording. |
| RB011 | Existing account/security sign-in options now reachable from collection. Real account/provider completion remains unverified. |
| RB012 | Provider remains unavailable on audited build. Added explanation and existing address/collection or basket recovery actions; authoritative checkout blocking preserved. Live provider completion remains open. |
| RB013 | Compact Help/info headings, GST settings, delivery selector and Store collection banner implemented using existing controls. |
| RB014 | Wholesale order/packs replaces Trade order/packs. |
| RB015 | Product visuals, product gallery and Orders promotional cards register with existing cart avoidance. |
| RB016 | Prior Offers brand palette fix retained. |
| RB017 | Publisher sheet scroll-controlled with explicit Android bottom inset. |
| RB018 | Benefit card uses a smaller responsive content threshold, keeping 44px actions and enlarged text. |
| RB019 | History thumbnail enlarged to fit its illustration disclosure instead of falling back at 48px. |
| RB021 | Category sheet explicitly uses one handle and opaque white content. |
| RB022 | Native request TextField is the sole field semantics owner; address tests passed. |
| RB023 | Finite and paged publisher filters restore MoolSocial consistently; All clears the flag and restores matching cards. |
| RB024 | Development source indexes the same displayed Store name; exact-name test passed. |
| RB025 | Store footer shows existing range/previous/next controls. |
| RB026 | Current source already normalizes Delivered to Delivery and labels recorded estimates; preserve and test. |
| RB027 | Saved retains active query/category and applies Wholesale/Bulk sale-type. |
| RB028 | Price-limited empty results explain the active cap and reset only that cap. |
| RB029 | Review source deliberately repeats template products to populate 5000 listings. Do not invent attributes or silently delete real listing identities; source/data disposition remains open. |
| RB030 | Store-identified product continuations use known same-store listings, excluding other sellers. Exact-seller test passed. |
| RB031 | Items alone render recorded product snapshots, quantity × pack and line amount; missing historical quantities are explicit. Reorder still uses current catalogue prices, verified with differing historical/current prices. |

Earlier session requests: storefront redesign, Store-specific categories/search/
Saved and restored More stores are present and included in current Store tests.
Delivery rail empty-state and Offers theme repairs are present locally. Pickup
selection exists for all Shop stores; authoritative address/auth/payment checks
remain. Existing user visual approvals do not substitute for these local tests.

- First focused analysis found the customer-copy extraction exported but did
  not import its extension in buy_v2_design.dart. Add its explicit import and
  repeat analysis; preserve the same customer copy and model identities. Three
  pre-existing session brace-style infos were also reported separately.

Additional local diagnostics: a file-local patch with out-of-order hunks was
atomically rejected; re-reading confirmed no mutation and ordered hunks applied.
Analysis rejected ListTile-only style arguments on SwitchListTile; styles moved
to its existing Text children. Current analysis exits 0, with only the three
inherited session brace-style infos. No checks were weakened.

## Final local validation and handoff

Evidence root: C:/GUARANTEED OUTCOME/outputs/cursor-buy-redmi-audit-20260922.
Logs are retained individually; overlapping runs are not a unique-test count.

| Run | Result |
| --- | --- |
| r1 | 18 passed, 2 optional captures skipped. |
| r2 | 239 passed, 1 skipped; 3 Offers keyboard failures retained. |
| r3 | All 4 original Offers keyboard profiles passed after the border-layout repair. |
| r4 | 603 passed, 1 skipped; Wholesale wording and Saved fixture failures retained. |
| r5 | Diagnostic failure confirmed Saved fixture belonged to an excluded fulfilment mode. |
| r6 | 47 passed, 1 skipped; corrected Saved fixture, wording and current-price Reorder checks passed. |
| r7 | 5 visual journeys passed, including Store normal/2x and Recent bottom clearance. |
| r8 | Publisher inset/selection test passed. Screenshot still contains Ahem fallback glyphs in ListTile labels despite the app theme; reject it as typography proof. Geometry/selection assertions remain valid. |

Final focused Dart analysis: exit 0, no errors or warnings, three inherited
brace-style infos. git diff --check passed. Final approved UI reference and
production locks passed unchanged. Actual Store and Recent local PNGs
were inspected; these are Flutter test captures, not a new Redmi qualification.
No assertions or production checks were weakened to achieve these results.

RB029 remains OPEN: the review source cycles a small template catalogue across
5000 listings. Authentic distinct listing content requires authoritative data;
inventing attributes or deleting identities would not be a production fix.
Supplier photos (RB005) and authenticated/provider-dependent completion
(RB011/RB012) also remain prerequisite limitations. They are not claimed passed.

Local implementation stops here as requested, with changes uncommitted. No new
APK, device installation, deployment, policy/gate edit or cross-worktree change.
The installed r66.31 remains unchanged; all current fixes need later device
qualification before claiming Redmi acceptance. The active goal is not marked
fully achieved while the documented data/provider limitations remain open.
