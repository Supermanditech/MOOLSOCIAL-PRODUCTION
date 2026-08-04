# Buy FV2 R58.2 search-result recovery handoff

Date: 3 August 2026

State: **FOUNDER APPROVED; PROTECT**

## Qualified outcome

R58.2 removes the proven no-match dead end when an exact product query is
trapped by the current category/filter. In expanded search, one native
`Search all <destination>` action appears only when the query is non-empty and
the current Shop, Wholesale or Medicine scope is narrowed. It clears category
and filter only, preserves exact query and current vertical, and reruns the
qualified R57 exact-first typo-tolerant ranking against real current-catalogue
products.

The action remains honest even when broadening finds nothing: it never invents
a result. Existing Clear and Finish search owners are reused, R58.1 product
continuation remains intact, Orders remain fail-closed and asynchronous
pagination is still dependency-held. The result transition is keyed to real
category/filter state and reuses approved finite R48 motion; reduced motion
renders the genuine state immediately/static.

## Exact qualified identity

- Candidate: `BUY-R58-SEARCH-RESULT-RECOVERY-FIX1`
- Profile: `1.0.0-r58.2` (`2026080315`)
- Branch: `remediation/prototype-conformance-2026-07-20`
- HEAD: `f1ac83dea2047f40b39d772696bd0d1224edce8e`
- Source: 2,417 app/test files, SHA-256
  `87C7B4182C554DCD2F0503AA2AC3480214FD60A5E70CAA8C1C44F4913AB9C679`
- APK/install: 134,017,505 bytes, SHA-256
  `9E6F762A03E41C0D41EA70465B46BEB7791BC6EB5EE11865A9680D0A1934BD72`
- Device: OPPO CPH2375, serial `2b3e0f71`

Pre-build, post-build and post-device source manifests match exactly. The OPPO
installed package reports the exact version/code and the pulled base APK is
checksum-identical to the wrapper-produced archive.

## Implementation and qualification

Runtime implementation is bounded to:

- `apps/mobile/lib/features/buy/buy_v2_session.dart` for fail-closed narrowed
  scope detection and query-preserving current-vertical broadening; and
- `apps/mobile/lib/ui_v2/buy/buy_v2_catalogue.dart` for the native recovery
  action and real scope-keyed result transition.

Deterministic coverage is in
`apps/mobile/test/ui_v2/buy/buy_v2_search_result_recovery_test.dart`.

Full analysis is clean. The focused suite passes 41/41. Two complete
unchanged-source Buy regressions each pass 298 active tests with the same 15
established intentional skips. Every positive release gate passes; the three
protected gates reach their exact expected fail-closed outcomes and no
protected baseline was replaced.

Connected-device proof covers real Shop, Wholesale and Medicine narrowed
no-match recovery, exact query/current vertical retention, R58.1 chained
product return, native `clickable=true` accessibility, keyboard and Back, hot
resume, approved force-stop restoration and zero app failures. The warmed
102-frame trace has presentation p95 18.721 ms, no frame over 33 ms, no frame
over 100 ms and no shader/compile event.

## Founder review points

On the installed OPPO, review:

1. Shop `MoolSocial value` + `atta` -> `Search all Shop` -> real Shop atta.
2. Atta detail -> `You may also like` -> another product -> one Back -> exact
   original Shop query/result.
3. Wholesale `Flexible packs` + `basmati` -> broaden -> real Wholesale rice.
4. Medicine `Everyday care` + `metformin` -> broaden -> Rx-labelled Metformin.
5. Finite result arrival, static reduced motion, and independent Clear,
   Finish search and system-Back behavior.

## Boundaries and next queue

The technical/device qualification did not itself constitute founder approval;
the subsequent founder disposition below approves the bounded candidate. It
neither implements fake pagination nor changes backend search, synonym/phonetic
expansion, location/serviceability, live stock, personalization, Cart,
payment, offers/coupons, Orders or B2B terms. R58.3 Cart continuation is the
next separate registered logical audit. R58.4-R58.8 remain queued separately.

Founder disposition after technical handoff: **approved and protected**. Exact
record:
`docs/quality/BUY-FV2-R58-2-FOUNDER-DISPOSITION-20260803.md`.

Evidence owner:
`artifacts/quality/buy-search-result-recovery-r58-2-20260803-125`.

Program matrix:
`docs/quality/BUY-R58-CONTINUOUS-NAVIGATION-TICKET-MATRIX-20260803.md`.
