# Buy V2 R36 motion, content and advertising contract

Date: 31 July 2026  
Candidate scope: `BUY-FV2-074` through `BUY-FV2-085` and
`BUY-FV2-117`  
Authority: founder-supervised Buy implementation tranche  
Baseline entering the tranche: protected R35.1 Buy and protected Social

## Non-negotiable boundaries

- Native Flutter remains the production UI. The approved HTML and its evidence
  remain read-only.
- Social and Screens 01–03 remain unchanged.
- The one Buy Cart remains aggregate across Shop, Wholesale and Medicine.
- No backend field, provider response, campaign, entitlement, price,
  availability, timing or measurement event is invented.
- Paid and video content stays absent until commercial, consent, moderation,
  click-through, measurement and provider contracts are approved.
- Motion acknowledges a real synchronous state change. It cannot pretend that
  synchronous navigation is loading and cannot create a perpetual decorative
  ticker.

## Ticket acceptance matrix

| Ticket | Candidate implementation | Acceptance state before founder replay |
| --- | --- | --- |
| `BUY-FV2-074` | One aggregate Cart with optional non-owning family filters, mixed-family fulfilment sections and exact return ownership | Mixed Shop/Wholesale/Medicine Cart and checkout checksum-matched OPPO verified |
| `BUY-FV2-075` | Customer-visible role language is `Mool Retail Partner`, `Mool Trade Partner`, `Mool Manufacturer Partner`, `Mool Pharmacy Partner` or `Mool Fulfilment Partner`; `Licensed pharmacy` remains a separate regulatory fact | Connected wording OPPO verified; founder combined review pending |
| `BUY-FV2-076` | Shared finite motion tokens cover press, selection, state change, content change, expand/collapse, route change, success, recovery and brand reveal; synchronous route acknowledgement states only the selected destination | Automated and checksum-matched device replay passed |
| `BUY-FV2-077` | Shop, Wholesale, Medicine and Orders have distinct related canvas/accent/header tokens; Cart/Checkout, Tracking/Items and Account/Assist use semantic screen-family overrides | Responsive tests and checksum-matched OPPO replay passed |
| `BUY-FV2-078` | The code-native mark keeps the existing M geometry, uses saffron/green strokes and navy anchors on white, reveals `MoolSocial` once, then rests compactly while the contextual header retains the full name | Candidate implemented; founder visual review pending |
| `BUY-FV2-079` | Stable product, promotion and order-card bounds acknowledge direct pointer intent with restrained sub-pixel depth; no free-running parallax, rotation or scene exists | Deterministic tests and checksum-matched OPPO replay passed |
| `BUY-FV2-080` | Replaceable product-facts adapter supports price, delivery commitment, partner and orderability in a fixed tile region, with source/time/stale contracts and approved-catalogue fallback | Candidate implemented; real provider not selected |
| `BUY-FV2-081` | Existing first-party promotion cards keep established actions and remain separate from products and paid content | Themed foundation and established actions OPPO verified |
| `BUY-FV2-082` | Replaceable sponsored-content boundary defines eligible slots and disclosure; one card maximum per catalogue; all slots collapse to zero because activation is not approved | Contract, fail-closed presentation and zero-height inactive slots verified |
| `BUY-FV2-083` | Inline-video data requires poster, captions and transcript; audio autoplay and preload are forbidden; no playback controller or provider is enabled | Contract verified; integration intentionally blocked |
| `BUY-FV2-084` | Deterministic motion/theme tests, accessibility fallbacks, responsive tests, performance limits and device evidence gate the tranche | Automated gates and OPPO interaction replay passed; release-hardware frame profiling remains open |
| `BUY-FV2-085` | One checksum-matched connected candidate covers the combined experience | Candidate ready; cannot close until the founder reviews it |
| `BUY-FV2-117` | Address/order projections are unmodifiable; stale identifiers cannot substitute another record; checkout/order details fail closed with owned recovery | Focused tests, two regressions and checksum-matched OPPO recovery/navigation replay passed |

## Motion ownership

| Intent | Token ceiling | Owner and fallback |
| --- | --- | --- |
| Press | 110 ms | The tapped control or stable card; static state/colour when motion is reduced |
| Selection | 150 ms | Category, filter, address, payment or destination owner |
| State change | 180 ms | Quantity, saved state, prescription state and Cart acknowledgement |
| Content change | 240 ms | Fixed-region facts only; no card reflow |
| Expand/collapse | 260 ms | Search, category and owned panels |
| Route change | 280 ms | Buy surface owner; no fake loading wording or spinner |
| Recovery | 220 ms | Explicit unavailable/stale owner and return action |
| Success | 360 ms | Completed action with real committed state |
| Brand reveal | 420 ms | One entry reveal followed by compact rest; never loops |

`MediaQuery.disableAnimations` resolves every shared duration to zero. The
reduced-motion route acknowledgement uses a static confirmation icon and exact
destination label. All critical surfaces remain opaque, so reduced
transparency does not expose content through glass effects. Header foreground
contrast is tested against every vertical theme. The existing viewport matrix
covers Android/iOS-size portrait and landscape layouts, 320-pixel compact
width, safe areas and 140% text.

## Theme ownership

| Surface | Visual role |
| --- | --- |
| Shop | Warm saffron-accented neutral commerce canvas |
| Wholesale | Green-accented trade canvas |
| Medicine | Calm teal-green health canvas; regulatory facts retain their own meaning |
| Orders | Royal/navy progress canvas |
| Cart, Checkout, Confirmation | Conversion family using saffron action emphasis |
| Tracking, Order Items | Progress family using semantic green |
| Account, Assist | MoolSocial navy/royal service family |

Themes may change presentation only. They cannot change product facts,
navigation, Cart ownership, payment, delivery, prescription or order rules.
Opaque surfaces are the reduced-transparency and low-end fallback. Dark-mode
expansion is not part of this tranche and must not be inferred from the current
light production theme.

## Product-facts contract

`BuyV2ProductFactsSnapshot` owns:

- exact product ID;
- positive current price;
- delivery commitment;
- named partner;
- orderability label;
- source ID;
- optional observation timestamp; and
- deterministic stale flag.

The initial and refreshed snapshot must validate before it can replace the
approved catalogue snapshot. A mismatched ID, non-positive price, empty
delivery/partner/orderability/source or unknown product fails closed. Initial
invalid content falls back to approved catalogue facts; an invalid explicit
refresh also exposes `Product information could not be refreshed.` Dynamic
facts cannot move price or quantity controls and cannot change card height.
No automatic cycling exists, so off-screen, touch-exploration and focused
control pause requirements are satisfied by absence rather than simulated
activity.

## Promotion and advertising placement contract

First-party MoolSocial promotion cards:

- open only established Buy actions;
- remain visually separate from product tiles;
- do not enter Checkout if they distract from delivery/payment decisions; and
- keep a compact honest state when unavailable.

Paid placements are limited to:

- after catalogue discovery;
- after order history; and
- before the Cart summary, never over it.

Density is at most one sponsored card per catalogue and one inline video per
viewport. Preloaded inline videos are zero. Disclosure must be exactly
`Sponsored` or `Advertisement`. A future ad must not cover product price,
quantity, Cart, address, delivery, payment, prescription or safety content.
Because no approved campaign/report/dismissal/measurement/provider contract
exists, `BuyV2Session.sponsoredContentActivationApproved` is `false`; even an
injected adapter returns no renderable content and its slot consumes zero
height.

## Inline-video contract

Any future inline video requires:

- an approved poster asset;
- captions and transcript;
- visible playback ownership;
- muted start and no audio autoplay;
- pause when off-screen or backgrounded;
- no automatic navigation or perpetual replay;
- data-saver, reduced-motion and low-bandwidth poster fallback;
- lifecycle-safe disposal;
- consent, moderation, click-through and measurement contracts; and
- a separately approved provider integration.

The R36 candidate deliberately contains no active video player. A static
presentation boundary is not production advertising activation.

### Founder-supplied Zepto placement references

Two current Zepto screenshots supplied by the founder from the connected OPPO
are preserved read-only under:

`artifacts/quality/buy-flutter-r36-motion-content-oppo-20260731-39/founder-reference-zepto-video-ads`

They are inspiration for interaction structure only. No Zepto brand,
advertisement, imagery, copy or implementation is copied. The reusable
observations for a future separately authorized MoolSocial implementation are:

- a compact picture-in-picture video may coexist with commerce only when its
  close, mute and expand controls are immediately visible;
- the picture-in-picture card must not cover Cart, price, quantity,
  prescription, delivery, payment, navigation or a product action;
- full-screen expansion must keep visible sound and close ownership and use at
  most one explicit CTA;
- compact and expanded states must preserve the same campaign identity,
  disclosure and playback state; and
- dismissal, backgrounding, data saver, reduced motion and low bandwidth must
  stop playback and retain an honest poster fallback.

These observations do not authorize a provider, campaign schema, player,
measurement event, click-through, autoplay or production activation.

## Performance and accessibility budgets

- Target frame time: 16.667 ms.
- Slow-frame ceiling: 33 ms.
- Maximum sponsored cards per catalogue: 1.
- Maximum inline videos per viewport: 1.
- Maximum preloaded inline videos: 0.
- Audio autoplay: forbidden.
- Perpetual decorative motion: forbidden.
- Critical tap targets: minimum 44 logical pixels.
- Candidate verification: focused analysis/tests, two same-source full Buy
  regressions, approved-reference/copy/brand/Social gates, checksum-matched APK
  installation and connected OPPO replay.

The guarded APK is 24,132 bytes larger than R35.1. App switch/hot resume and
the installed checksum passed on OPPO. No crash, Flutter exception or ANR was
found in the final replay log.

Android `gfxinfo` from the debug review build reported 82 frames with 13.41%
jank, a 23 ms p90 and a 53 ms p95 while screenshot/UI-automation activity was
also present. A controlled post-reset sample exposed zero Flutter SurfaceView
frames and therefore could not validate or refute that result. Both raw
outputs are preserved. They are diagnostic evidence, not release-performance
acceptance. `BUY-FV2-084` remains open for profile/release-mode measurement on
representative hardware and founder review.

## Founder gate

Passing automated or device gates does not close `BUY-FV2-085`. The founder
must review the combined connected candidate. A new protected Buy baseline may
be recorded only after that review and explicit acceptance; backend work does
not begin merely because the implementation compiles or tests pass.
